import CONSTANTS from "../Constants";

import { ActorContext } from "../ActorContext"
import { useContext }   from "react";

const Welcome = () => {

  const {login} = useContext(ActorContext);

  return (
    <div className="w-full flex xl:lg:md:flex-row flex-col min-h-screen items-center justify-center">
      <div className="xl:lg:md:w-1/2 w-full flex flex-col leading-none items-center justify-center min-h-half-screen space-y-5">
        <div className="xl:text-humongous lg:text-9xl md:text-8xl text-6xl font-bold text-black dark:text-white"> Godwin </div>
        <div className="xl:text-humongous-5 lg:text-humongous-4 md:text-humongous-3 text-humongous-2 text-black dark:text-white"> { CONSTANTS.LOGO } </div>
      </div>
      <div className="xl:lg:md:w-1/2 w-full flex flex-col items-center justify-center text-black dark:text-white xl:text-5xl lg:text-4xl md:text-3xl text-2xl font-bold">
        <h1>Explore values.</h1>
        <h1>Thrust nuances.</h1>
        <button type="button" onClick={login} className="button-blue mt-5 xl:text-2xl lg:text-xl md:text-lg text-md">
          Log in
        </button>
      </div>
    </div>
  );
}

export default Welcome;