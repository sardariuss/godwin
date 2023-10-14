import React from "react";

type TabButtonProps = {
  isCurrent: boolean,
  setIsCurrent: () => (void),
  children?: React.ReactNode,
};

export const TabButton = ({isCurrent, setIsCurrent, children}: TabButtonProps) => {

  return (
    <button 
      className={
        "inline-block flex flex-row justify-center w-full xl:px-4 lg:px-3 sm:px-2 px-1 py-4 border-b-2 " 
        + (isCurrent ? "dark:text-white border-blue-700 font-bold" : 
          "border-transparent text-gray-600 hover:text-black hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent() }>
        { children }
    </button>
  );

};