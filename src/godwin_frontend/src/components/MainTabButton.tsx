
type Properties = {
  label: string,
  isCurrent: boolean,
  setIsCurrent: () => (void),
};

export const MainTabButton = ({label, isCurrent, setIsCurrent}: Properties) => {

  return (
    <button 
      className={
        "inline-block p-4 w-full " 
        + (isCurrent ? "text-white font-bold bg-gray-800 " : 
          "border-transparent hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent()}>
        {label}
    </button>
  );

};