import React, { useState, useEffect } from "react";

type TextInputProps = {
  id: string;
  label: string;
  dir?: "ltr" | "rtl";
  onInputChange: (string) => void;
  value: string;
  isValid?: (string) => boolean;
}

const TextInput = ({id, label, dir, onInputChange, value, isValid}: TextInputProps) => {

  const [text, setText] = useState<string>(value);

  // Update from within
  const updateText = (new_text: string) => {
    setText(new_text);
    onInputChange(new_text);
  };

  // Update from outside
  useEffect(() => {
    if (text !== value){
      setText(value);
    };
  }, [value]);

  return (
    <div dir={dir?? "ltr"}>
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
          className="absolute text-sm text-gray-500 dark:text-gray-400 duration-300 transform -translate-y-3 scale-75 top-0 start-0 peer-focus:text-blue-600 peer-focus:dark:text-blue-500 peer-placeholder-shown:scale-100 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:top-1/2 top-1 z-10 peer-focus:px-2 peer-focus:top-1 peer-focus:scale-75 peer-focus:-translate-y-3"
        >
          {label}
        </label>
        <p className={`mt-2 text-xs text-red-600 dark:text-red-400 ${isValid === undefined ? "hidden" : isValid(text) ? "hidden" : ""}`}><span className="font-medium">Error: </span>Some error message.</p>
      </div>
    </div>
  );
};

export default TextInput;