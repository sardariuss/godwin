import { ActorContext } from "../ActorContext"

import { useContext }   from "react";

function Footer() {

  const {isAuthenticated, authClient} = useContext(ActorContext);

  return (
		<>
      {
        isAuthenticated && authClient !== undefined ? 
        /* Uses the same padding as in the header */ 
        <footer className="w-full bg-slate-100 dark:bg-gray-800 shadow flex flex-row items-center justify-between xl:px-4 lg:px-3 md:px-2 px-2 xl:h-18 lg:h-16 md:h-14 h-14">
          <a href="https://internetcomputer.org/">
            <div className="flex flex-row items-center">
              <div className="sm:text-center text-l font-semibold text-gray-500 dark:text-gray-400">
                Powered by
              </div>
              <div className="w-2"/>
              <img src="ic-logo.svg" className="flex h-5" alt="the IC"/>
            </div>
          </a>
          <div className="flex flex-row justify-end items-center space-x-3">
            <div className="text-black dark:text-white text-sm font-extralight">
              {/* @todo: this parameter shouldn't be hardcoded*/}
              alpha v0.1.0
            </div>
            <a href="https://discord.gg/ZAvUSPRA" className="button-svg h-6 w-6 pt-0.5">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 127.14 96.36"><g><g id="Discord_Logos" data-name="Discord Logos"><g id="Discord_Logo_-_Large_-_White" data-name="Discord Logo - Large - White"><path d="M107.7,8.07A105.15,105.15,0,0,0,81.47,0a72.06,72.06,0,0,0-3.36,6.83A97.68,97.68,0,0,0,49,6.83,72.37,72.37,0,0,0,45.64,0,105.89,105.89,0,0,0,19.39,8.09C2.79,32.65-1.71,56.6.54,80.21h0A105.73,105.73,0,0,0,32.71,96.36,77.7,77.7,0,0,0,39.6,85.25a68.42,68.42,0,0,1-10.85-5.18c.91-.66,1.8-1.34,2.66-2a75.57,75.57,0,0,0,64.32,0c.87.71,1.76,1.39,2.66,2a68.68,68.68,0,0,1-10.87,5.19,77,77,0,0,0,6.89,11.1A105.25,105.25,0,0,0,126.6,80.22h0C129.24,52.84,122.09,29.11,107.7,8.07ZM42.45,65.69C36.18,65.69,31,60,31,53s5-12.74,11.43-12.74S54,46,53.89,53,48.84,65.69,42.45,65.69Zm42.24,0C78.41,65.69,73.25,60,73.25,53s5-12.74,11.44-12.74S96.23,46,96.12,53,91.08,65.69,84.69,65.69Z"/></g></g></g></svg>
            </a>
            <div className="icon-svg h-6 w-6">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
            </div>
          </div>
        </footer> : <></>
      }
    </>
  );
}

export default Footer;