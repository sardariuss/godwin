import React, { useState, useEffect, useRef } from "react";

import CircularProgress from '@mui/joy/CircularProgress';

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
  callback_function: (T) => boolean;
  trigger_update: boolean;
  set_trigger_update: (boolean) => void;
}

const UpdateProgress = <T,>({delay_duration_ms, update_function, callback_function, trigger_update, set_trigger_update}: Props<T>) => {

  const interval_duration_ms = 50;

  const [interval, setInterval] = useState<number | null>(null);
  const [countdownProgress, setCountdownProgress] = useState<number>(delay_duration_ms);
  const [updateProgress, setUpdateProgress] = useState<boolean>(false);
  const [success, setSuccess] = useState<boolean | null>(null);

  useEffect(() => {
    if (trigger_update) {
      set_trigger_update(false);
      refreshInterval();
    }
  }, [trigger_update]);

  useInterval(() => {
    //console.log("countdownProgress: " + countdownProgress)
    if (countdownProgress > 0) {
      //console.log("countdownProgress: update")
      setCountdownProgress((progress) => progress - interval_duration_ms);
    } else {
      //console.log("countdownProgress: stop")
      setCountdownProgress(delay_duration_ms);
      setInterval(null);
      update();
    }
  }, interval);

  const update = () => {
    setUpdateProgress(true);
    update_function().then((result) => {
      setUpdateProgress(false);
      setSuccess(callback_function(result));
    });
	};

  const refreshInterval = () => {
    //console.log("refreshInterval: start")
    setSuccess(null);
    setCountdownProgress(delay_duration_ms);
    setInterval(interval_duration_ms);
  }

	return (
    <CircularProgress
      color={success === null ? "primary" : (success ? "success" : "danger")} 
      determinate={!updateProgress}
      value={updateProgress ? 30 : (countdownProgress / delay_duration_ms) * 100 }
      variant="plain"
      size="sm"
    >
      <div className="w-3/4">
      {
        success === null ? <></> :
          success ? 
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960" fill="green"><path d="M378 815.739 148.261 586l48.978-48.978L378 717.782l383.761-383.76L810.739 383 378 815.739Z"/></svg> :
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960" fill="red"><path d="M445.935 678.63V290.5h68.13v388.13h-68.13Zm0 182.87v-68.13h68.13v68.13h-68.13Z"/></svg>
      }
      </div>
    </CircularProgress>
	);
};

export default UpdateProgress;