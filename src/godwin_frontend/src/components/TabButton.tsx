import React from "react";

type TabButtonProps = {
  label: string,
  isCurrent: boolean,
  setIsCurrent: () => (void),
};

export const TabButton = ({label, isCurrent, setIsCurrent}: TabButtonProps) => {

  return (
    <button 
      className={
        "inline-block p-4 border-b-2 " 
        + (isCurrent ? "dark:text-white border-blue-700 font-bold" : 
          "border-transparent text-gray-600 hover:text-black hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent()}>
        {label}
    </button>
  );

};