import Balance                          from "./base/Balance";
import { ActorContext }                 from "../ActorContext"

import { Link }                         from "react-router-dom";
import React, { useContext, useEffect } from "react";
import CONSTANTS                        from "../Constants";

type Props = {
  login: () => (void),
  setShowAskQuestion: (boolean) => (void)
};

function Header({login, setShowAskQuestion}: Props) {

  const {isAuthenticated, authClient, balance, loggedUserName} = useContext(ActorContext);

  useEffect(() => {

    var themeToggleDarkIcon = document.getElementById('theme-toggle-dark-icon');
    var themeToggleLightIcon = document.getElementById('theme-toggle-light-icon');
    var themeToggleBtn = document.getElementById('theme-toggle');

    if (themeToggleDarkIcon == null || themeToggleLightIcon == null || themeToggleBtn == null) {
      return;
    };
  
    // Change the icons inside the button based on previous settings
    if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        themeToggleLightIcon.classList.remove('hidden');
    } else {
        themeToggleDarkIcon.classList.remove('hidden');
    }
  
    themeToggleBtn.addEventListener('click', function() {
  
        // toggle icons inside button
        themeToggleDarkIcon.classList.toggle('hidden');
        themeToggleLightIcon.classList.toggle('hidden');
  
        // if set via local storage previously
        if (localStorage.getItem('color-theme')) {
            if (localStorage.getItem('color-theme') === 'light') {
                document.documentElement.classList.add('dark');
                localStorage.setItem('color-theme', 'dark');
            } else {
                document.documentElement.classList.remove('dark');
                localStorage.setItem('color-theme', 'light');
            }
  
        // if NOT set via local storage previously
        } else {
            if (document.documentElement.classList.contains('dark')) {
                document.documentElement.classList.remove('dark');
                localStorage.setItem('color-theme', 'light');
            } else {
                document.documentElement.classList.add('dark');
                localStorage.setItem('color-theme', 'dark');
            }
        }
        
    });

  }, []);

  return (
		<>
      <header className="bg-slate-100 dark:bg-gray-800 sticky top-0 z-20 w-full px-2 sm:px-4 py-2.5">
        <div className="container flex flex-row justify-between items-center mx-auto">
          <Link to="/">
            <div className="flex flex-row items-center">
              <img src="battery.svg" className="w-10 h-10" alt="Logo"/>
              <div className="w-2"></div>
              <div className="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Godwin</div>
            </div>
          </Link>
          <div className="hidden w-full md:block md:w-auto" id="mobile-menu">
            <ul className="flex flex-col items-center mt-4 md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium items-center">
              <li>
                <button id="theme-toggle" type="button" className="fill-indigo-600 hover:fill-indigo-900 dark:fill-yellow-400 dark:hover:fill-yellow-200 rounded-lg text-sm p-2.5">
                  <svg id="theme-toggle-dark-icon" className="hidden w-5 h-5" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path></svg>
                  <svg id="theme-toggle-light-icon" className="hidden w-5 h-5" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" fillRule="evenodd" clipRule="evenodd"></path></svg>
                </button>
              </li>
              { isAuthenticated ? 
                <li>
                  <button type="button" onClick={(e) => setShowAskQuestion(true)} className="button-blue">
                    Propose a vote
                  </button>
                </li> : <></>
              }
              <li>
                <Link to={"/newsub"} className="button-blue">
                  Create sub
                </Link>
              </li>
              <li>
                { isAuthenticated && authClient !== undefined ? 
                  <Link to={"/profile/" + authClient.getIdentity().getPrincipal().toString()} className="block text-gray-700 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">
                    { loggedUserName !== undefined ? loggedUserName : CONSTANTS.USER_NAME.DEFAULT }
                  </Link> :
                  <button type="button" onClick={login} className="button-blue">
                    Log in
                  </button>
                }
              </li>
              { isAuthenticated ? 
                <li className="text-black dark:text-white">
                  <Balance amount={ balance !== null ? balance : undefined } />
                </li> : <></>
              }
            </ul>
          </div>
        </div>
      </header>
    </>
  );
}

export default Header;