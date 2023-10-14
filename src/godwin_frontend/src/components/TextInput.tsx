import React, { useState, useEffect } from "react";

type TextInputProps = {
  id: string;
  label: string;
  dir?: "ltr" | "rtl";
  input: string | undefined;
  onInputChange: (input: string | undefined) => void;
  validate?: (input: string) => Promise<string | undefined>;
}

const TextInput = ({id, label, dir, onInputChange, input, validate}: TextInputProps) => {

  const [text,  setText]  = useState<string | undefined>(input    );
  const [error, setError] = useState<string | undefined>(undefined);
  
  // Update from within
  const updateText = (new_text: string | undefined) => {
    if (validate !== undefined){
      if (new_text === undefined || new_text.length === 0){
        setError(undefined);
      } else {
        validate(new_text).then((res) => {
          setError(res);
        });
      }
    }
    setText(new_text);
    onInputChange(new_text);
  };

  // Update text from outside
  useEffect(() => {
    if (text !== input){
      updateText(input);
    };
  }, [input]);

  useEffect(() => {
    // Initial validation
    updateText(input);
  }, []);

  return (
    <div dir={dir?? "ltr"} className="py-1">
      <div className="relative">
        <input 
          type="text" 
          id={id}
          className={`block px-0.5 pb-1.5 pt-3 w-full text-sm text-gray-900 bg-transparent rounded-lg border-1 border-gray-300 appearance-none dark:text-white dark:border-gray-600 dark:focus:border-blue-500 focus:outline-none focus:ring-0 focus:border-blue-600 peer
            ${dir !== undefined && dir === "rtl" ? "text-right" : "text-left"}`}
          placeholder=" "
          onChange={(e) => { updateText(e.target.value); }} 
          value={text}
        />
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
};

export default TextInput;