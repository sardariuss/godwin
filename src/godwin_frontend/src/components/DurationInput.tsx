import { Duration }                   from "../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect } from "react";

type Parameter = {
  unit: string,
  min: number,
  max: number,
};

const parameters : Parameter[] = [
  { unit: 'HOURS',   min: 1,   max: 120  },
  { unit: 'DAYS',    min: 1,   max: 1000 },
  { unit: 'YEARS',   min: 1,   max: 100  },
];

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

type DurationInputProps = {
  label: string;
  onInputChange: (Duration) => void;
  value: Duration;
};

const DurationInput = ({label, value, onInputChange} : DurationInputProps) => {

  const [selectedParameter, setSelectedParameter] = useState<Parameter>(parameters[0]    );
  const [selectedAmount,    setSelectedAmount   ] = useState<number>   (parameters[0].min);

  // Update from within
  const updateUnit = (new_unit: string) => {
    setSelectedParameter(old => { return parameters.find(({unit}) => unit === new_unit ) ?? old; });
  }

  // Update from within
  const updateAmount = (new_amount: number) => {
    setSelectedAmount(new_amount < selectedParameter.min ? selectedParameter.min : new_amount > selectedParameter.max ? selectedParameter.max : new_amount);
  }

  useEffect(() => {
    // Callback to parent
    onInputChange({[selectedParameter.unit]: BigInt(selectedAmount)});
    // Make sure to revalidate the amount when the unit changes
    updateAmount(selectedAmount);
  }, [selectedParameter]);

  useEffect(() => {
    // Callback to parent
    onInputChange({[selectedParameter.unit]: BigInt(selectedAmount)});
  }, [selectedAmount]);

  // Update from outside
  useEffect(() => {
    updateUnit(getDurationUnit(value));
    updateAmount(Number(getDurationAmount(value)));
  }, []);

  return (
    <div className="grid grid-cols-3 gap-x-2 items-center">
      <label className="block text-sm font-medium text-gray-900 dark:text-white">{label}</label>
      <input dir="rtl" className="w-16 justify-self-end appearance-none dark:bg-transparent dark:text-white" type="number" min={selectedParameter.min} max={selectedParameter.max} onChange={(e) => updateAmount(Number(e.target.value))} value={selectedAmount}></input>
      <select value={selectedParameter.unit} onChange={(e) => {updateUnit(e.target.value)}} id="states" className="w-24 justify-self-start bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg border-l-gray-100 dark:border-l-gray-700 border-l-2 focus:ring-blue-500 focus:border-blue-500 block p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500">
        {
          parameters.map(({unit}, index) => (
            <option key={index.toString()} className="w-24" value={unit}>{unit}</option>
          ))
        }
      </select>
    </div>
  );
}

export default DurationInput;