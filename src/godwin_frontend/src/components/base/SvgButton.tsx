type Props = {
  onClick   : (e: React.MouseEvent<HTMLButtonElement, MouseEvent>) => void;
  disabled  : boolean;
  hidden    : boolean;
  children? : React.ReactNode;
}

const SvgButton = ({onClick, disabled, hidden, children} : Props) => {
  return (
    <button className={`w-full button-svg text-gray-700 dark:text-gray-300 ${disabled ? "" : "hover:text-black dark:hover:text-white"}`} onClick={ (e) => { onClick(e) } } hidden={hidden} disabled={disabled}>
      { children }
    </button>
  );
}

export default SvgButton;