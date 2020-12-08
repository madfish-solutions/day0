type account is record [
    balance : nat;
    allowances : map (address, nat);
]

type storage is record [
    totalSupply : nat;
    ledger : big_map (address, account);
]

type transfer_type is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type approve_type is michelson_pair(address, "spender", nat, "value")
type balance_type is michelson_pair(address, "owner", contract(nat), "")
type allowance_type is michelson_pair(michelson_pair(address, "owner", address, "spender"), "", contract(nat), "")
type total_supply_type is michelson_pair(unit, "", contract(nat), "")
type redeem_type is nat
type mint_type is unit

type action is 
| Mint of mint_type
| Default of mint_type
| Redeem of redeem_type
| Transfer of transfer_type
| Approve of approve_type
| GetBalance of balance_type
| GetAllowance of allowance_type
| GetTotalSupply of total_supply_type

function getAccount(const owner : address; const s : storage) : account is 
case s.ledger[owner] of None -> record [
    balance = 0n;
    allowances = (map [] : map(address, nat));
]
| Some(acc) -> acc
end

function transfer(const owner : address; const receiver : address; const value : nat; const s : storage) : storage is
block {
    const src : account = getAccount(owner, s);
    const dst : account = getAccount(receiver, s);
    if Tezos.sender = owner then skip else block {
        const allowance : nat = case src.allowances[Tezos.sender] of 
        | None -> 0n
        | Some(v) -> v
        end;
        if allowance < value then failwith("NotPermitted") else 
        src.allowances[Tezos.sender] := abs(allowance - value);
    };
    if src.balance < value then failwith("LowBalance") else skip;
    src.balance := abs(src.balance - value);
    dst.balance := dst.balance + value;
    s.ledger[owner] := src;
    s.ledger[receiver] := dst;
} with s

function approve(const spender : address; const value : nat; const s : storage) : storage is
block {
    const acc : account = getAccount(Tezos.sender, s);
    acc.allowances[spender] := value;
    s.ledger[Tezos.sender] := acc;
} with s

function getAllowance(const owner : address; const spender : address; const receiver : contract(nat); const s : storage) : list(operation) is
block {
    const acc : account = getAccount(owner, s);
    const allowance : nat = case acc.allowances[spender] of 
    | None -> 0n
    | Some(v) -> v
    end
} with list [Tezos.transaction(allowance, 0mutez, receiver)]

function getBalance(const owner : address; const receiver : contract(nat); const s : storage) : list(operation) is
block {
    const acc : account = getAccount(owner, s);
} with list [Tezos.transaction(acc.balance, 0mutez, receiver)]

function getTotalSupply(const receiver : contract(nat); const s : storage) : list(operation) is
list [Tezos.transaction(s.totalSupply, 0mutez, receiver)]

function mint(const s : storage) : storage is
block {
    const acc : account = getAccount(Tezos.sender, s);
    acc.balance := acc.balance + Tezos.amount / 1mutez;
    s.ledger[Tezos.sender] := acc;
} with s

function redeem(const value : nat; const s : storage) : (list(operation) * storage) is
block {
    const acc : account = getAccount(Tezos.sender, s);
    if acc.balance < value then
        failwith("NotEnoughBalance")
    else skip;
    acc.balance := abs(acc.balance - value);
    s.ledger[Tezos.sender] := acc;
    const receiver : contract(unit) = case (Tezos.get_contract_opt (Tezos.sender) : option(contract(unit))) of
        Some (contract) -> contract
    | None -> (failwith ("InvalidContract") : (contract(unit)))
    end;
} with (list [Tezos.transaction(unit, value * 1mutez, receiver)], s)
