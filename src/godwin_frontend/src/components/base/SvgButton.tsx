type Props = {
  onClick   : () => void;
  disabled  : boolean;
  hidden    : boolean;
  children? : React.ReactNode;
}

const SvgButton = ({onClick, disabled, hidden, children} : Props) => {
  return (
    <button className={`w-full button-svg`} onClick={ (e) => { if (!disabled) onClick() } } hidden={hidden}>
      { children }
    </button>
  );
}

export default SvgButton;