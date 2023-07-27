import { Duration }                   from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect } from "react";

const units : string[] = ['YEARS', 'DAYS', 'HOURS', 'MINUTES'];

const getDurationUnit = (duration: Duration) : string => {
  if (duration['YEARS']   !== undefined) return 'YEARS';
  if (duration['DAYS']    !== undefined) return 'DAYS';
  if (duration['HOURS']   !== undefined) return 'HOURS';
  if (duration['MINUTES'] !== undefined) return 'MINUTES';
  if (duration['SECONDS'] !== undefined) return 'SECONDS';
  if (duration['NS']      !== undefined) return 'NS';
  throw new Error("Invalid duration");
}

const getDurationAmount = (duration: Duration) : bigint => {
  if (duration['YEARS']   !== undefined) return duration['YEARS'];
  if (duration['DAYS']    !== undefined) return duration['DAYS'];
  if (duration['HOURS']   !== undefined) return duration['HOURS'];
  if (duration['MINUTES'] !== undefined) return duration['MINUTES'];
  if (duration['SECONDS'] !== undefined) return duration['SECONDS'];
  if (duration['NS']      !== undefined) return duration['NS'];
  throw new Error("Invalid duration");
}

const updateUnit = (duration: Duration, unit: string) : Duration => {
  if (unit === 'YEARS')   return {'YEARS':   getDurationAmount(duration)};
  if (unit === 'DAYS')    return {'DAYS':    getDurationAmount(duration)};
  if (unit === 'HOURS')   return {'HOURS':   getDurationAmount(duration)};
  if (unit === 'MINUTES') return {'MINUTES': getDurationAmount(duration)};
  if (unit === 'SECONDS') return {'SECONDS': getDurationAmount(duration)};
  if (unit === 'NS')      return {'NS':      getDurationAmount(duration)};
  throw new Error("Invalid duration");
}

const updateAmount = (duration: Duration, amount: number) : Duration => {
  if (getDurationUnit(duration) === 'YEARS')   return {'YEARS':   BigInt(amount)};
  if (getDurationUnit(duration) === 'DAYS')    return {'DAYS':    BigInt(amount)};
  if (getDurationUnit(duration) === 'HOURS')   return {'HOURS':   BigInt(amount)};
  if (getDurationUnit(duration) === 'MINUTES') return {'MINUTES': BigInt(amount)};
  if (getDurationUnit(duration) === 'SECONDS') return {'SECONDS': BigInt(amount)};
  if (getDurationUnit(duration) === 'NS')      return {'NS':      BigInt(amount)};
  throw new Error("Invalid duration");
}

type DurationInputProps = {
  id: string;
  label: string;
  onInputChange: (Duration) => void;
  input: Duration;
  validate?: (Duration) => Promise<string | undefined>;
};

const DurationInput = ({id, label, input, onInputChange, validate} : DurationInputProps) => {

  const [duration, setDuration] = useState<Duration>(input);

  const [error, setError] = useState<string | undefined>(undefined);

  useEffect(() => {
    // Callback to parent
    onInputChange(duration);
    // Validation
    validate?.(duration).then((res) => {
      setError(res);
    });
  }, [duration]);

  return (
    <div className="relative pb-1 w-54">
      <div className="flex flex-row gap-x-2 items-center">
        <input dir="rtl"
          id={id}
          className={`block px-0.5 pb-1.5 pt-3 w-20 text-sm text-gray-900 bg-transparent rounded-lg border-1 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-blue-500 focus:outline-none focus:ring-0 focus:border-blue-600 peer`}
          type="number" min={0} onChange={(e) => setDuration(old => { return updateAmount(old, Number(e.target.value)); })} value={Number(getDurationAmount(duration))}></input>
        <select value={getDurationUnit(duration)} onChange={(e) => {setDuration(old => { return updateUnit(old, e.target.value); });}} id="states" className="mt-1 w-24 justify-self-start bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg border-l-gray-100 dark:border-l-gray-700 border-l-2 focus:ring-blue-500 focus:border-blue-500 block px-2.5 py-1 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500">
          {
            units.map((unit, index) => (
              <option key={index.toString()} className="w-24" value={unit}>{unit}</option>
            ))
          }
        </select>
        <label
            htmlFor={id}
            className="absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-3 scale-100 top-0 start-0 peer-focus:text-blue-600 peer-focus:dark:text-blue-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 -top-1 z-10 peer-focus:px-2 peer-focus:-top-1 peer-focus:scale-100 peer-focus:-translate-y-3"
          >
          {label}
        </label>
      </div>
      <p className={`absolute font-medium text-xs text-red-600 dark:text-red-400 ${error === undefined ? "hidden" : ""}`}>{error}</p>
    </div>
  );
}

export default DurationInput;