
type Properties = {
  label: string,
  isCurrent: boolean,
  setIsCurrent: () => (void),
};

export const MainTabButton = ({label, isCurrent, setIsCurrent}: Properties) => {

  return (
    <button 
      className={
        "inline-block py-4 w-full hover:bg-gray-100 hover:dark:bg-slate-850 " 
        + (isCurrent ? "dark:text-white font-bold " : 
          "border-transparent hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent()}>
        {label}
    </button>
  );

};