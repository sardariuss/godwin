type Props = {
  reset: () => void;
  disabled: boolean;
}

const ResetButton = ({reset, disabled} : Props) => {
  return (
    <button className={`flex h-5 w-5 button-svg`} onClick={ (e) => { if (!disabled) reset() } }>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960" ><path d="M481 898q-131 0-225.5-94.5T161 578v-45l-80 80-39-39 149-149 149 149-39 39-80-80v45q0 107 76.5 183.5T481 838q29 0 55-5t49-15l43 43q-36 20-72.5 28.5T481 898Zm289-169L621 580l40-40 79 79v-41q0-107-76.5-183.5T480 318q-29 0-55 5.5T376 337l-43-43q36-20 72.5-28t74.5-8q131 0 225.5 94.5T800 578v43l80-80 39 39-149 149Z"/></svg>
    </button>
  );
}

export default ResetButton;