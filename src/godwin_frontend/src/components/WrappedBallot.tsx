import { useEffect, useState, useContext } from "react";

import { CursorInfo, VoteKind, voteKindToCandidVariant } from "../utils";

import Ballot from "./votes/Ballot";

import { Question, TransactionsRecord, PayoutResult } from "../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../ActorContext";

import { fromNullable } from "@dfinity/utils";

import { Sub } from "../ActorContext";

export type BallotInfo = {
  vote_kind: VoteKind,
  vote_id: bigint,
  cursor: CursorInfo | undefined,
  date: bigint | undefined,
  tx_record: TransactionsRecord | undefined,
};

export type WrappedBallotInput = {
  sub: Sub,
  ballot_info: BallotInfo
};

export const WrappedBallot = ({sub, ballot_info}: WrappedBallotInput) => {

  const {token} = useContext(ActorContext);

  const [question, setQuestion] = useState<Question | undefined>(undefined);
  const [iteration, setIteration] = useState<bigint | undefined>(undefined);
  const [payin, setPayin] = useState<bigint | undefined>(undefined);
  const [refund, setRefund] = useState<bigint | undefined>(undefined);
  const [reward, setReward] = useState<bigint | undefined>(undefined);
	
  const refreshQuestionIteration = async () => {
    setQuestion(old => { return undefined; });
    setIteration(old => { return undefined; });
    setIteration(undefined);
    let question_iteration = await await sub.actor.getQuestionIteration(voteKindToCandidVariant(ballot_info.vote_kind), ballot_info.vote_id)
    if (question_iteration['ok'] !== undefined){
      setQuestion(old => { return question_iteration['ok'][0] });
      setIteration(old => { return question_iteration['ok'][1] });
    }
  }

  const refreshPayin = async () => {
    setPayin(old => { return undefined; });
    if (ballot_info.tx_record !== undefined){
      let tx = fromNullable(await token.get_transaction(ballot_info.tx_record.payin));
      if (tx !== undefined){
        let transfer = fromNullable(tx.transfer);
        setPayin(old => { return transfer !== undefined ? transfer.amount : undefined; });
      }
    }
  }

  const refreshRefund = async () => {
    setRefund(old => { return undefined; });
    if (ballot_info.tx_record !== undefined && ballot_info.tx_record.payout['PROCESSED'] !== undefined) {
      let refund : PayoutResult | undefined = fromNullable(ballot_info.tx_record.payout['PROCESSED'].refund);
      if (refund !== undefined && refund['ok'] !== undefined){
        let tx = fromNullable(await token.get_transaction(refund['ok']));
        if (tx !== undefined){
          let transfer = fromNullable(tx.transfer);
          setRefund(old => { return transfer !== undefined ? transfer.amount : undefined; });
        }
      }
    }
  }

  const refreshReward = async () => {
    setReward(old => { return undefined; });
    if (ballot_info.tx_record !== undefined && ballot_info.tx_record.payout['PROCESSED'] !== undefined) {
      let reward : PayoutResult | undefined = fromNullable(ballot_info.tx_record.payout['PROCESSED'].reward);
      if (reward !== undefined && reward['ok'] !== undefined){
        let tx = fromNullable(await token.get_transaction(reward['ok']));
        if (tx !== undefined){
          let transfer = fromNullable(tx.transfer);
          setReward(old => { return transfer !== undefined ? transfer.amount : undefined; });
        }
      }
    }
  }

  useEffect(() => {
    refreshQuestionIteration();
    refreshPayin();
    refreshRefund();
  }, [ballot_info]);

	return (
    <div className="flex flex-col py-1 px-6 w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2">
      <div className="grid grid-cols-4 w-full">
        <div className="col-span-3 w-full justify-start text-sm font-normal">
          { question !== undefined ? question.text : "" }
        </div>
        {
          ballot_info.cursor !== undefined && ballot_info.date !==undefined ?
          <Ballot cursorInfo={ballot_info.cursor} dateNs={ballot_info.date} /> : <></>
        }
      </div>
      <div>
        { refund !== undefined && payin !== undefined ? 
            (refund - payin) > 0 ?
              <div className="text-xs text-green-500"> {"⬆🪙 " + (refund - payin).toString() } </div> :
            (refund - payin) <= 0 ?
              <div className="text-xs text-red-500"> {"⬇🪙 " + (refund - payin).toString() } </div>
            : 
              <div className="text-xs text-red-500"> {"≈🪙 " + (refund - payin).toString() } </div> 
          :
          <></>
        }
      </div>
      <div>
        { payin !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div>{ "Payin: 🪙 " + payin.toString()}</div>
          </div> :
          <></>
        }
      </div>
      <div>
        { refund !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div> { "Refund: 🪙 " + refund.toString()} </div>
          </div> :
          <></>
        }
      </div>
      <div>
        { reward !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div> { "Reward: 🪙 " + reward.toString()} </div>
          </div> :
          <></>
        }
      </div>
    </div>
	);
};

export default WrappedBallot;
