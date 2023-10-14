import React, { useState } from 'react';
import Spinner             from './Spinner';

import { Tooltip }         from "@mui/material";
import ErrorOutlineIcon    from "@mui/icons-material/ErrorOutline";
import DoneIcon            from '@mui/icons-material/Done';

enum SubmittingState {
  STILL,
  SUBMITTING,
  SUCCESS,
  ERROR,
};

type SubmitButtonProps<T> = {
  submit: () => Promise<T>,
  children?: React.ReactNode,
};

const SubmitButton = <T,>({submit, children} : SubmitButtonProps<T>) => {

  const [state, setState] = useState<SubmittingState>   (SubmittingState.STILL);
  const [error, setError] = useState<string | undefined>(undefined            );

  const submitHandler = () => {
    if (state !== SubmittingState.SUBMITTING){
      setState(SubmittingState.SUBMITTING);
      setError(undefined);
      (async function() {
        try {
          await submit();
          setState(SubmittingState.SUCCESS);
        } catch(e: any) {
          setState(SubmittingState.ERROR);
          setError(e.toString());
        }
      })()
    }
  }

  return (
    <div className="flex flex-row items-center space-x-2">
      <button className="button-simple min-w-36 min-h-8 flex flex-col items-center" disabled={state === SubmittingState.SUBMITTING} type="submit" onClick={(e) => submitHandler() }>
        {
          state === SubmittingState.SUBMITTING ?
            <div className="w-5 h-5">
              <Spinner/>
            </div> 
          :
          children
        }
      </button>
      <div className="flex flex-col w-6 min-w-6 items-center text-sm">
        {
          state === SubmittingState.ERROR ?
            <div className="w-full">
              <Tooltip title={error} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip>
            </div> : 
          state === SubmittingState.SUCCESS ?
            <div className="w-full">
              <DoneIcon color="success"/>
            </div> :
            <></>
        }
      </div>
    </div>
  );
}

export default SubmitButton;