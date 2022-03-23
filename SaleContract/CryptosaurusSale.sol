// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./ICryprosaurus.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";

contract CryptosaurusSale is Ownable {

    address public _treasury;

    ICryprosaurus private immutable _NFT;
    IERC20Metadata private immutable _ERC20;
    address public _recipient;             // who will receive payment

    uint public _bodySkinScope;            // initialization value: 3
    uint public _eyeSkinScope;             // initialization value: 16
    uint public _scaleScope;               // initialization value: 100
    uint public _blindPrice;               // initialization value: 0

    struct initInput{
        uint kind;
        uint salePrice;
        uint numberLimit;
    }

    struct saurusContext{
        uint kind;
        uint salePrice;
        uint numberLimit;
        uint number;
    }

    saurusContext[] public _saurus;

    event SaurusUpdate(initInput input, uint updateMethod);
    event UpdatePrice(uint indexed kind, uint price);
    event UpdateNumberLimit(uint indexed kind, uint numberLimit);
    event Purchase(address indexed to, uint price, uint kind);
    event UpdateBlindPrice(uint price);

    constructor(address nft, address erc20, address recipient) {
        _NFT = ICryprosaurus(nft);
        _ERC20 = IERC20Metadata(erc20);
        _recipient = recipient;

        _bodySkinScope = 3;
        _eyeSkinScope = 16;
        _scaleScope = 100;
        _blindPrice = 0;
    }

    function saurusKindAmount() external view returns(uint256){
        return _saurus.length;
    }

    function setRecipient(address recipient) external onlyOwner {
        _recipient = recipient;
    }

    function setBodySkinScope(uint value) external onlyOwner {
        _bodySkinScope = value;
    }

    function setEyeSkinScope(uint value) external onlyOwner {
        _eyeSkinScope = value;
    }

    function setScaleScope(uint value) external onlyOwner {
        _scaleScope = value;
    }

    function batchInitialization(initInput[] calldata input) external onlyOwner {
        require(_saurus.length == 0, "batchInit fail for _saurus no empty");
        require(input.length > 0, "batchInit fail for input is empty");

        for (uint i = 0; i < input.length; i++) {
            _updateSaurus(input[i], 0, 0);
        }

        _updateBlindPrice();
    }

    function addSaurus(initInput calldata input) external onlyOwner {
        require(_saurus.length > 0, "addSaurus fail for _saurus is empty");

        for (uint i = 0; i < _saurus.length; i++) {
            if ( _saurus[i].kind == input.kind ) {
                require(false, "addSaurus fail for kind has existed");
            }
        }

        _updateSaurus(input, 0, 1);
        _updateBlindPrice();
    }

    function updatePrice(uint kind, uint price) external onlyOwner {
        require(price > 0, "revisePrice fail for price zero");

        uint pos = _findSaurus(kind);
        require(pos < _saurus.length, "revisePrice fail for not find kind");
        _saurus[pos].salePrice = price;

        _updateBlindPrice();
        emit UpdatePrice(kind, price);
    }

    function updateNumber(uint kind, uint numberLimit) external onlyOwner {
        uint pos = _findSaurus(kind);

        require( numberLimit > _saurus[pos].number ,"numberLimit fail for Limit less than current number");

        require(pos < _saurus.length, "revisePrice fail for not find kind");
        _saurus[pos].numberLimit = numberLimit;
        emit UpdateNumberLimit(kind, numberLimit);
    }

    function blindBox(uint price, address to) external {
        require(_saurus.length > 0, "blindBox fail for _saurus is empty");
        require(_blindPrice > 0, "blindBox fail for _blindPrice is zero");
        require(price >= _blindPrice, "blindBox fail for price < _blindPrice");
        uint pos = 0;
        uint selects = 0;

        while ( selects < 3 ) {
            pos = _rand()%_saurus.length;
            if ( _saurus[pos].number < _saurus[pos].numberLimit ) {
                break;
            }
            selects++;
        }
        require(selects < 3, "blindBox fail for select overtime");
        _purchase(_saurus[pos], msg.sender, price, to);
    }

    function purchase(uint kind, uint price, address to) external {
        uint pos = _findSaurus(kind);
        require(pos < _saurus.length, "purchase fail for not find kind");
        require(_saurus[pos].number < _saurus[pos].numberLimit, "purchase fail for number over");
        _purchase(_saurus[pos], msg.sender, price, to);
    }

    function _updateBlindPrice() internal {
        uint totalPrice = 0;
        uint tmp = 0;
        require(_saurus.length > 0, "_updateBlindPrice fail for _saurus empty");
        for (uint i = 0; i < _saurus.length; i++) {
            tmp = totalPrice;
            totalPrice = tmp + _saurus[i].salePrice;
            require(totalPrice > tmp, "_updateBlindPrice fail for price overflow");
        }
        _blindPrice = totalPrice / _saurus.length;
        emit UpdateBlindPrice(_blindPrice);
    }

    function _purchase(
        saurusContext storage context,
        address user,
        uint price,
        address to
    )
        internal
    {
        ICryprosaurus.mintInput memory input;
        input.context.kind = context.kind;
        input.context.bodySkin = _rand()%_bodySkinScope;
        input.context.eyeSkin = _rand()%_eyeSkinScope;
        input.context.scale = _rand()%_scaleScope + 1;
        input.to = to;
        _NFT.mint(input);
        context.number = context.number + 1;
        _ERC20.transferFrom(user, _recipient, price);
        emit Purchase(to, price, context.kind);
    }

    function _updateSaurus(initInput calldata input, uint number, uint method) internal {
        saurusContext memory context;

        require(input.salePrice > 0, "Set sale price is zero");

        context.kind = input.kind;
        context.salePrice = input.salePrice;
        context.numberLimit = input.numberLimit;
        context.number = number;
        _saurus.push(context);

        emit SaurusUpdate(input, method);
    }

    function _findSaurus(uint kind) internal view returns (uint) {
        uint i = 0;
        while ( i < _saurus.length ) {
            if ( _saurus[i].kind == kind ) {
                break;
            }
            i++;
        }

        return i;
    }

    function _rand() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}
