type CreateSubButtonProps = {
  label: string;
  show: boolean;
  setShow: (boolean) => void;
  children: React.ReactNode;
}

const CreateSubButton = ( {label, show, setShow, children} : CreateSubButtonProps) => {

  return (
    <div className="w-full border border-b-0 border-gray-200 dark:border-gray-700 hover:bg-gray-100 dark:hover:bg-gray-800">
      <button
        className="flex flex-row items-center w-full p-2 font-medium text-left text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 space-x-1" onClick={(e) => setShow(!show) }>
        <div className="icon-svg w-5 h-5">
          {
            show ?
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M200-450v-60h560v60H200Z"/></svg> :
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960"><path d="M480-345 240-585l43-43 197 198 197-197 43 43-240 239Z"/></svg>
          }
        </div>
        <div>{label}</div>
      </button>
      <div className={`flex flex-col items-center mx-10 ${show ? "" : "hidden"} `}>
        { children }
      </div>
    </div>
  );
}

export default CreateSubButton;