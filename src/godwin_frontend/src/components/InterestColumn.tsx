
type Props = {
  children?: React.ReactNode;
}

const InterestColumn = ({children} : Props) => {
  return (
    <div className="flex flex-col items-center fill-black dark:fill-white">
      <svg viewBox="0 0 1024 1024" className="w-2/3 icon-svg hover:icon-svg-hover" xmlns="http://www.w3.org/2000/svg"><path d="M264.8 604.7l61.8 61.8L512 481.1l185.4 185.4 61.8-61.8L512 357.5z"/></svg>
        { children }
      <svg viewBox="0 0 1024 1024" className="w-2/3 icon-svg hover:icon-svg-hover" xmlns="http://www.w3.org/2000/svg"><path d="M759.2 419.8L697.4 358 512 543.4 326.6 358l-61.8 61.8L512 667z"/></svg>
    </div>
  );
};

export default InterestColumn;