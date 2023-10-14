import React, { useState, useEffect } from "react";

type NumberInputProps = {
  id: string;
  label: string;
  onInputChange: (input: number) => void;
  input: number | undefined;
  validate?: (input: number) => Promise<string | undefined>;
  precision?: number;
};

const NumberInput = ({id, label, input, onInputChange, validate, precision} : NumberInputProps) => {

  //const [value, setValue] = useState<number | undefined>(input);

  const [error, setError] = useState<string | undefined>(undefined);

  const validateValue = (value: number | undefined) => {
    setError(undefined);
    if (validate !== undefined && value !== undefined){
      validate(value).then((res) => {
        setError(res);
      });
    }
  }

//  useEffect(() => {
//    // Callback to parent
//    onInputChange(value);
//    // Validation
//    if (value !== undefined){
//      validate?.(value).then((res) => {
//        setError(res);
//      });
//    }
//  }, [value]);

  return (
    <div className="py-1">
      <div className="relative hover:cursor-pointer">
        <input 
          id={id}
          className={`block px-0.5 pb-1.5 pt-3 w-full text-sm text-gray-900 bg-transparent rounded-lg border-1 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-blue-500 focus:outline-none focus:ring-0 focus:border-blue-600 peer`}
          type="number"
          min={0}
          placeholder={" "}
          onChange={(e) => { onInputChange(Number(e.target.value))} }
          onBlur={(e) => { validateValue(Number(e.target.value))} }
          step={precision !== undefined ? Math.pow(10, -1 * precision) : 1 }
        >
        </input>
        <label
            htmlFor={id}
            className="absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-3 scale-100 top-0 start-0 peer-focus:text-blue-600 peer-focus:dark:text-blue-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 top-1 z-10 peer-focus:px-2 peer-focus:top-1 peer-focus:scale-100 peer-focus:-translate-y-3"
          >
          {label}
        </label>
        <p className={`absolute font-medium -mt-2 text-xs text-red-600 dark:text-red-400 ${error === undefined ? "hidden" : ""}`}>{error}</p>
      </div>
    </div>
  );
}

export default NumberInput;