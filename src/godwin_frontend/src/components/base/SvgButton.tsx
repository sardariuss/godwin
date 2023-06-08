type Props = {
  onClick   : () => void;
  disabled  : boolean;
  hidden    : boolean;
  children? : React.ReactNode;
}

const SvgButton = ({onClick, disabled, hidden, children} : Props) => {
  return (
    <button className={`w-full button-svg`} onClick={ (e) => { onClick() } } hidden={hidden} disabled={disabled}>
      { children }
    </button>
  );
}

export default SvgButton;