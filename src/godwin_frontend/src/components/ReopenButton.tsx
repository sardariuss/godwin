import Balance                         from "./base/Balance"
import { _SERVICE, Status }            from "../../declarations/godwin_sub/godwin_sub.did"
import Spinner                         from "./Spinner";
import { ActorContext }                from "../ActorContext";

import { Tooltip }                     from "@mui/material";
import ErrorOutlineIcon                from '@mui/icons-material/ErrorOutline';

import { ActorSubclass }               from "@dfinity/agent"
import React, { useState, useContext } from "react"

type ReopenButtonInput = {
  actor: ActorSubclass<_SERVICE>,
  questionId: bigint,
  onReopened: (bigint) => void
}

const ReopenButton = ({actor, questionId, onReopened}: ReopenButtonInput) => {

  const {refreshBalance} = useContext(ActorContext);

  const [submitting,    setSubmitting   ] = useState<boolean>      (false);
  const [error,         setError        ] = useState<string | null>(null );

  const reopenQuestion = () => {
    setSubmitting(true);
    setError(null);
    actor.reopenQuestion(questionId).then((res) => {
      setSubmitting(false);
      if (res['ok'] !== undefined) {
        refreshBalance();
        onReopened(questionId);
      } else if (res['err'] !== undefined) {
        const error : Array<[[] | [Status], string]> = res['err'];
        if (error.length > 0) {
          setError(error[0][1]);
        } else {
          setError("Unknown error");
        }
      } else {
        throw new Error("Invalid reopen question result");
      }
    });
  }

  return (
    <div className="flex flex-col items-center gap-y-1">
      <button className="button-simple w-24 min-w-24 h-11 px-2 text-xs flex flex-col justify-center items-center" type="button" onClick={(e) => { reopenQuestion(); } }>
      {
        submitting ?
        <div className="w-5 h-5">
          <Spinner/>
        </div> :
        <div className="flex flex-col items-center gap-y-1">
          Propose again
          <Balance amount={BigInt(1_000_000_000)}/>
        </div>
      }
      </button>
      <div className="flex flex-col w-6 min-w-6 items-center text-sm">
      {
        error !== null ?
        <div className="w-full">
          <Tooltip title={error} arrow>
            <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
          </Tooltip>
        </div> : 
        <></>
      }
      </div>
    </div>
  )
}

export default ReopenButton