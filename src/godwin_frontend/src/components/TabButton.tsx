
type TabButtonProps = {
  label: string,
  isCurrent: boolean,
  setIsCurrent: () => (void),
};

export const TabButton = ({label, isCurrent, setIsCurrent}: TabButtonProps) => {

  return (
    <button 
      className={
        "inline-block p-4 border-b-2 rounded-t-lg " 
        + (isCurrent ? "text-white border-blue-700 font-bold" : 
          "border-transparent hover:text-gray-600 hover:border-gray-300 dark:hover:text-gray-300")
      } 
      type="button"
      role="tab"
      onClick={(e) => setIsCurrent()}>
        {label}
    </button>
  );

};