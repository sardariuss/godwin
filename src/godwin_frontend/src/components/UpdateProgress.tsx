import Balance                                from "./base/Balance";
import SvgButton                              from "./base/SvgButton";

import React, { useState, useEffect, useRef } from "react";

import CircularProgress                       from '@mui/joy/CircularProgress';
import { Tooltip }                            from "@mui/material";
import ErrorOutlineIcon                       from '@mui/icons-material/ErrorOutline';
import DoneIcon                               from '@mui/icons-material/Done';
import { CssVarsProvider, extendTheme }       from '@mui/joy/styles';

// This part could be declared in your theme file
declare module '@mui/joy/CircularProgress' {
  interface CircularProgressPropsSizeOverrides {
    custom: true;
  }
}

const theme = extendTheme({
  components: {
    JoyCircularProgress: {
      styleOverrides: {
        root: ({ ownerState, theme }) => ({
          ...(ownerState.size === 'custom' && {
            '--CircularProgress-trackThickness': '2px',
            '--CircularProgress-progressThickness': '2px',
            '--CircularProgress-trackColor': 'transparent',
            '--_root-size': 'var(--CircularProgress-size, 25px)', // use --_root-size to let other components overrides via --CircularProgress-size
          }),
          ...(ownerState.instanceSize === 'custom' && {
            '--CircularProgress-size': '25px',
          })
        }),
      },
    },
  },
});


function useInterval(callback, delay) {
  const savedCallback = useRef<any>();

  // Remember the latest callback.
  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  // Set up the interval.
  useEffect(() => {
    function tick() {
      savedCallback.current();
    }
    if (delay !== null) {
      let id = setInterval(tick, delay);
      return () => clearInterval(id);
    }
  }, [delay]);
}

type Props<Error> = {
  delay_duration_ms : number;
  run_countdown     : boolean;
  trigger_update    : boolean;
  children?         : React.ReactNode;
  update_function   : ()        => Promise<Error | null>;
  callback_success  : ()        => Promise<void>;
  error_to_string   : (Error)   => string;
  set_run_countdown : (boolean) => void;
  set_trigger_update: (boolean) => void;
  cost?             : bigint;
}

const UpdateProgress = <Error,>({
  delay_duration_ms, 
  update_function, 
  callback_success, 
  error_to_string, 
  run_countdown, 
  set_run_countdown, 
  trigger_update, 
  set_trigger_update, 
  children,
  cost}: Props<Error>) => {

  const interval_duration_ms = 50;

  const [interval,          setInterval         ] = useState<number | null>(null );
  const [countdownProgress, setCountdownProgress] = useState<number | null>(null );
  const [updateProgress,    setUpdateProgress   ] = useState<boolean>      (false);
  const [error,             setError            ] = useState<string | null>(null );

  useEffect(() => {
    if (run_countdown && countdownProgress === null) {
      setCountdownProgress(delay_duration_ms);
      setInterval(interval_duration_ms);
      setError(null);
    } else if (!run_countdown) {
      stopCountdown();
    }
  }, [run_countdown]);

  useEffect(() => {
    if (countdownProgress !== null && countdownProgress <= 0) {
      triggerUpdate();
    }
  }, [countdownProgress]);

  useEffect(() => {
    if (trigger_update && updateProgress === false) {
      triggerUpdate();
    }
  }, [trigger_update]);

  useInterval(() => {
    setCountdownProgress((progress) => {
      return progress !== null && progress > 0 ? progress - interval_duration_ms : progress;
    });
  }, interval);

  const triggerUpdate = () => {
    stopCountdown();
    setUpdateProgress(true);
    set_trigger_update(true);
    update_function().then((err) => {
      let callback = err === null ? callback_success : () => { return Promise.resolve(); };
      callback().then(() => {
        setUpdateProgress(false);
        setError(err === null ? null : error_to_string(err));
        set_trigger_update(false);
      });
    });
  }

  const stopCountdown = () => {
    set_run_countdown(false);
    setCountdownProgress(null);
    setInterval(null);
    setError(null);
  }

	return (
    <div className="relative flex flex-col items-center w-full">
      { 
        error === null ? 
          <CssVarsProvider theme={theme}>
            <CircularProgress
              color="primary"
              determinate={!updateProgress}
              value={updateProgress ? 40 : countdownProgress ? (countdownProgress / delay_duration_ms) * 100 : 0}
              variant="soft"
              size="custom"
              sx={{
                '--CircularProgress-progressColor': `${ document.documentElement.classList.contains('dark') ? "rgb(209 213 219)" : "rgb(55 65 81)" }`,
              }}
            >
              <div className="w-full flex flex-col items-center z-10">
              {
                
                updateProgress ? <></> 
                : countdownProgress !== null ? 
                  <div className="w-3/4">
                    <SvgButton onClick={() => { stopCountdown(); }} disabled={false} hidden={false}>
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M240-240v-480h480v480H240Z"/></svg>
                    </SvgButton>
                  </div> 
                : <div className="w-7 h-7">{children}</div> 
              }
              </div>
            </CircularProgress>
          </CssVarsProvider>
        : <div className="w-full flex flex-col items-center z-10">
          {
            error.length !== 0 ?
              <Tooltip title={error} enterTouchDelay={100} arrow>
                <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
              </Tooltip> 
            : <DoneIcon color="success"/>
          }
          </div>
      }
      <div className="absolute pt-6 flex flex-col w-full items-center">
      {
        cost !== undefined && error === null && !updateProgress ?
        <div className="text-xs pt-1">
          <Balance amount={cost}/>
        </div> : <></>
      }
      </div>
    </div>
	);
};

export default UpdateProgress;