import React from "react";

type TabButtonProps = {
  label: string,
  isCurrent: boolean,
  setIsCurrent: () => (void),
  isHelpVisible: boolean,
  setIsHelpVisible: React.Dispatch<React.SetStateAction<boolean>>
};

export const TabButton = ({label, isCurrent, setIsCurrent, isHelpVisible, setIsHelpVisible}: TabButtonProps) => {

  return (
    <button 
      className={
        "inline-block xl:px-4 lg:px-3 sm:px-2 px-1 py-4 border-b-2 " 
        + (isCurrent ? "dark:text-white border-blue-700 font-bold" : 
          "border-transparent text-gray-600 hover:text-black hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent() }>
        <div className="flex flex-row items-center">
          {label}
          { isCurrent ? 
            <div className="flex flex-col button-svg w-5 h-5" onClick={(e) => { setIsHelpVisible(!isHelpVisible); }}>
              <svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M478-240q21 0 35.5-14.5T528-290q0-21-14.5-35.5T478-340q-21 0-35.5 14.5T428-290q0 21 14.5 35.5T478-240Zm-36-154h74q0-33 7.5-52t42.5-52q26-26 41-49.5t15-56.5q0-56-41-86t-97-30q-57 0-92.5 30T342-618l66 26q5-18 22.5-39t53.5-21q32 0 48 17.5t16 38.5q0 20-12 37.5T506-526q-44 39-54 59t-10 73Zm38 314q-83 0-156-31.5T197-197q-54-54-85.5-127T80-480q0-83 31.5-156T197-763q54-54 127-85.5T480-880q83 0 156 31.5T763-763q54 54 85.5 127T880-480q0 83-31.5 156T763-197q-54 54-127 85.5T480-80Zm0-80q134 0 227-93t93-227q0-134-93-227t-227-93q-134 0-227 93t-93 227q0 134 93 227t227 93Zm0-320Z"/></svg>
            </div> : <></>
          }
        </div>
    </button>
  );

};