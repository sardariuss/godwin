import ICRC1 "mo:icrc1/ICRC1";

module {

  // Types inherited from ICRC1 token

  public type Account                 = ICRC1.Account;
  public type Subaccount              = ICRC1.Subaccount;
  public type AccountBalances         = ICRC1.AccountBalances;

  public type Transaction             = ICRC1.Transaction;
  public type Balance                 = ICRC1.Balance;
  public type TransferArgs            = ICRC1.TransferArgs;
  public type Mint                    = ICRC1.Mint;
  public type BurnArgs                = ICRC1.BurnArgs;
  public type TransactionRequest      = ICRC1.TransactionRequest;
  public type TransferError           = ICRC1.TransferError;

  public type SupportedStandard       = ICRC1.SupportedStandard;

  public type InitArgs                = ICRC1.InitArgs;
  public type TokenInitArgs           = ICRC1.TokenInitArgs;
  public type TokenData               = ICRC1.TokenData;
  public type MetaDatum               = ICRC1.MetaDatum;
  public type TxLog                   = ICRC1.TxLog;
  public type TxIndex                 = ICRC1.TxIndex;

  public type TokenInterface          = ICRC1.TokenInterface;
  public type RosettaInterface        = ICRC1.RosettaInterface;
  public type FullInterface           = ICRC1.FullInterface;

  public type ArchiveInterface        = ICRC1.ArchiveInterface;

  public type GetTransactionsRequest  = ICRC1.GetTransactionsRequest;
  public type GetTransactionsResponse = ICRC1.GetTransactionsResponse;
  public type QueryArchiveFn          = ICRC1.QueryArchiveFn;
  public type TransactionRange        = ICRC1.TransactionRange;
  public type ArchivedTransaction     = ICRC1.ArchivedTransaction;

  public type TransferResult          = ICRC1.TransferResult;

  ///////////////////////////////////////////

  // Additional types specific to godwin

  public type ReapAccountError = {
    #InsufficientFunds : { balance : Balance; };
    #NoRecipients;
    #NegativeShare: ReapAccountRecipient;
    #BalanceExceeded : { 
      sum_shares: Float; 
      total_amount: Balance;
      balance_without_fees: Balance;
    };
  };

  public type ReapAccountResult = {
    #Ok : [ (TransferArgs, TransferResult)];
    #Err : ReapAccountError;
  };

  public type ReapAccountRecipient = {
    account : Account;
    share : Float;
  };

  public type ReapAccountArgs = {
    subaccount : ?Subaccount;
    to : [ReapAccountRecipient];
    memo : ?Blob;
    /// The time at which the transaction was created.
    /// If this is set, the canister will check for duplicate transactions and reject them.
    // @todo: this cannot be used with the current reap_account implementation, because many
    // transfer are done at the same time.
    //created_at_time : ?Nat64;
  };

  public type MintRecipient = {
    account : Account;
    amount : Balance;
  };

  public type MintBatchArgs = {
    to : [MintRecipient];
    memo : ?Blob;
  };

  public type MintBatchResult = {
    #Ok : [(Mint, TransferResult)];
    #Err : TransferError;
  };

}