import CONSTANTS from "../Constants";

import { ActorContext } from "../ActorContext"
import { useContext }   from "react";

const Welcome = () => {

  const {login} = useContext(ActorContext);

  return (
    <div className="w-full flex xl:lg:md:flex-row flex-col min-h-screen items-center justify-center">
      <div className="xl:lg:md:w-3/5 w-full flex flex-col items-center justify-center min-h-half-screen space-x-2">
        <div className="xl:text-8xl lg:text-6xl md:text-5xl text-5xl text-black dark:text-white title">Politiballs</div>
        <img src="balls.png" alt="balls" className="xl:lg:md:w-3/4 w-1/2"></img>
      </div>
      <div className="xl:lg:md:w-2/5 w-full flex flex-col items-center justify-center text-black dark:text-white xl:text-5xl lg:text-4xl md:text-3xl text-3xl font-bold">
        <h1 className="catchphrase">Time to grow some.</h1>
        <button type="button" onClick={login} className="button-blue mt-5 xl:text-2xl lg:text-xl md:text-lg text-md">
          Log in
        </button>
      </div>
    </div>
  );
}

export default Welcome;