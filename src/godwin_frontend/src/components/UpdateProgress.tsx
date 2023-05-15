import React, { useState, useEffect, useRef } from "react";

import CircularProgress                 from '@mui/joy/CircularProgress';
import { Tooltip }                      from "@mui/material";
import ErrorOutlineIcon                 from '@mui/icons-material/ErrorOutline';
import DoneIcon                         from '@mui/icons-material/Done';
import { CssVarsProvider, extendTheme } from '@mui/joy/styles';

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
  const savedCallback = useRef();

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

type Props<T> = {
  delay_duration_ms: number;
  update_function: () => Promise<T>;
  callback_function: (T) => string;
  run_countdown: boolean;
  set_run_countdown: (boolean) => void;
  trigger_update: boolean;
  set_trigger_update: (boolean) => void;
  children?: React.ReactNode;
}

const UpdateProgress = <T,>({delay_duration_ms, update_function, callback_function, run_countdown, set_run_countdown, trigger_update, set_trigger_update, children}: Props<T>) => {

  const interval_duration_ms = 50;

  const [interval, setInterval] = useState<number | null>(null);
  const [countdownProgress, setCountdownProgress] = useState<number | null>(null);
  const [updateProgress, setUpdateProgress] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (run_countdown && countdownProgress === null) {
      setCountdownProgress(delay_duration_ms);
      setInterval(interval_duration_ms);
      setError(null); // @todo: probably not needed
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
    update_function().then((result) => {
      setUpdateProgress(false);
      setError(callback_function(result));
      set_trigger_update(false);
    });
  }

  const stopCountdown = () => {
    set_run_countdown(false);
    setCountdownProgress(null);
    setInterval(null);
    setError(null);
  }

	return (
    <div className="flex relative justify-items-center justify-center w-full">
      <div className="relative flex w-full" style={{visibility: updateProgress === false && countdownProgress === null ? "hidden" : "visible"}}>
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
        </CircularProgress>
        </CssVarsProvider>
      </div>
      <div className="flex flex-col absolute grow w-full z-10 items-center">
        {
          updateProgress ? 
            <></> :
          countdownProgress?
            <div className="flex w-full items-center text-center place-content-center text-gray-700 hover:text-black dark:text-gray-300 dark:hover:text-white hover:cursor-pointer" onClick={(e) => stopCountdown()}>◼</div> :
          error === null ?
            children : error.length !== 0 ?
            <Tooltip title={error} arrow>
              <ErrorOutlineIcon color="error"></ErrorOutlineIcon>
            </Tooltip> :
            <DoneIcon color="success"></DoneIcon>
          }
      </div>
    </div>
	);
};

export default UpdateProgress;