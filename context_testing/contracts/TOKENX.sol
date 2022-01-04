// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/Context.sol"; 
import "hardhat/console.sol";


contract TOKENX is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    uint256 private _totalSupply = 1000000000 * 10**6 * 10**18; // 10^15 total supply

    uint256 private _taxLiquidityPercentage = 4000;  

    string private _name = "Simple Token";
    string private _symbol = "STK";
    uint8 private _decimals = 18;
    
    /** Configure wallet before Deployments */
    address private _foundersWallet  = 0x6788c1925F87c53DDe5BB5d3F9fA27B5F8e2e274;
    address private _liquidityWallet = 0xF53dF1faD7691423a0F2789BE0D2642dC3d8a482;


    // Pancakeswap Router for Mainnet (Uncomment while Deployment)
    // address private _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    // address private _routerFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // address private _routerWETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // Pancakeswap Router for testnet
    address private _router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; 
    address private _routerFactory = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address private _routerWETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address private _liquidityPool;
    address private _wethAddress;
    constructor()
    {
       

        // UNCOMMENTT THIS WHILE DEPOYMENT
        // _liquidityPool = IUniswapV2Factory(_routerFactory)
        //                  .createPair(address(this), _routerWETH);
        // _wethAddress = _routerWETH;
        // _allowances[address(this)][address(_router)] = ~uint256(0);

        // Sends 100% of total supply to founder's wallet // 
        _balances[_foundersWallet] = _totalSupply.mul(100).div(100); 

        /** Few Wallets are excluded from the Fees */
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_foundersWallet] = true; 
        _isExcludedFromFees[_liquidityWallet] = true; 
        
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == _foundersWallet, 'Only owner can call this function');
        _;
    }
    function excludeAddressFromFees(address excludedAddress) public onlyOwner
    {
        _isExcludedFromFees[excludedAddress] = true;
    }
    
    function totalSupply() public view virtual override returns (uint256)
    {
        return _totalSupply;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    /**
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        
        return true;
    }
    /**
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    /**
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        
        return true;
    }
    /**
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        if (recipient != _liquidityPool && sender != _liquidityPool) 
        {
            _beforeTokenTransfer(sender, recipient, amount);
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            _afterTokenTransfer(sender, recipient, amount);
            
        }
        // This is a buy/sell to liquidity pool where either buyer or seller are excluded from taxes
        else if (_isExcludedFromFees[recipient] || _isExcludedFromFees[sender]) 
        {
            _beforeTokenTransfer(sender, recipient, amount);
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            _afterTokenTransfer(sender, recipient, amount);
        }
        // This is a buy/sell to liquidity pool where a portion of tax gets sent to designated wallets
        else if (recipient == _liquidityPool || sender == _liquidityPool) 
        {   
            uint256 taxLiquidity = amount.mul(_taxLiquidityPercentage).div(100000);
            
            // liquidity wallet receives liquidity tax
            _balances[_liquidityWallet] += taxLiquidity; 

            // buyer receives amount minus tax
            _balances[recipient] += (amount - (taxLiquidity)); 
            
            emit Transfer(sender, _liquidityWallet, taxLiquidity);
            emit Transfer(sender, recipient, (amount - (taxLiquidity)));
        }
        
    }
   
    function mint(
        address account,
        uint256 amount
    ) public onlyOwner {
        _mint(account, amount);
    }
    

    function _mint(
        address account, 
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

   
    function burn(
        uint256 amount
    ) public onlyOwner {
        _burn(address(this), amount);
    }
    function _burn(
        address account, 
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    receive() external payable {}
}