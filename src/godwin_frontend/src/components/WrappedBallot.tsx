import { useEffect, useState, useContext } from "react";

import { CursorInfo, VoteKind, voteKindToCandidVariant } from "../utils";

import CursorBallot from "./votes/CursorBallot";

import { Question, TransactionsRecord, ReapAccountResult, MintResult } from "../../declarations/godwin_backend/godwin_backend.did";

import { ActorContext } from "../ActorContext";

import { fromNullable } from "@dfinity/utils";

import { Sub } from "../ActorContext";
import CONSTANTS from "../Constants";

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
      let refund : ReapAccountResult | undefined = fromNullable(ballot_info.tx_record.payout['PROCESSED'].refund);
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
      let reward : MintResult | undefined = fromNullable(ballot_info.tx_record.payout['PROCESSED'].reward);
      if (reward === undefined){
      } else if (reward['ok'] !== undefined){
        let tx = fromNullable(await token.get_transaction(reward['ok']));
        if (tx !== undefined){
          console.log("there is a tx: " + tx.toString());
          let mint = fromNullable(tx.mint);
          setReward(old => { return mint !== undefined ? mint.amount : undefined; });
        }
      } else {
        console.log(reward);
      }
    }
  }

  useEffect(() => {
    refreshQuestionIteration();
    refreshPayin();
    refreshRefund();
    refreshReward();
  }, [ballot_info]);

	return (
    <div className="flex flex-col py-1 px-6 w-full text-black dark:text-white border-b dark:border-gray-700 hover:bg-slate-50 hover:dark:bg-slate-850 py-2">
      <div className="grid grid-cols-4 w-full">
        <div className="col-span-3 w-full justify-start text-sm font-normal">
          { question !== undefined ? question.text : "" }
        </div>
        {
          ballot_info.cursor !== undefined && ballot_info.date !==undefined ?
          <CursorBallot cursorInfo={ballot_info.cursor} dateNs={ballot_info.date} /> : <></>
        }
      </div>
      <div>
        { refund !== undefined && reward !== undefined && payin !== undefined ? 
            (refund + reward - payin) > 0 ?
              <div className="text-xs text-green-500"> {"⬆🪙 " + (refund + reward- payin).toString() } </div> :
            (refund + reward - payin) <= 0 ?
              <div className="text-xs text-red-500"> {"⬇🪙 " + (refund + reward- payin).toString() } </div>
            : 
              <div className="text-xs text-red-500"> {"≈🪙 " + (refund + reward - payin).toString() } </div> 
          :
          <></>
        }
      </div>
      <div>
        { payin !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div>{ "Payin: " + payin.toString() + " " + CONSTANTS.COIN_EMOJI }</div>
          </div> :
          <></>
        }
      </div>
      <div>
        { refund !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div> { "Refund: " + refund.toString() + " " + CONSTANTS.COIN_EMOJI } </div>
          </div> :
          <></>
        }
      </div>
      <div>
        { reward !== undefined ?
          <div className="flex flex-col text-xs text-gray-500 dark:text-gray-400">
            <div> { "Reward: " + reward.toString() + " " + CONSTANTS.COIN_EMOJI } </div>
          </div> :
          <></>
        }
      </div>
    </div>
	);
};

export default WrappedBallot;
