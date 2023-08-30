import Balance                                    from "./base/Balance";
import { ActorContext }                           from "../ActorContext"
import useClickOutside                            from "../utils/useClickOutside";
import CONSTANTS                                  from "../Constants";

import { Link }                                   from "react-router-dom";
import React, { useContext, useEffect, useState,
  useRef, useCallback } from "react";

type Props = {
  login: () => (void),
  setShowAskQuestion: (boolean) => (void)
};

function Header({login, setShowAskQuestion}: Props) {

  const {isAuthenticated, authClient, balance, loggedUserName} = useContext(ActorContext);

  const [showMenu, setShowMenu] = useState<boolean>(false);

  const popover = useRef<any>();

  const close = useCallback(() => { setShowMenu(false); }, []);
  useClickOutside(popover, close);

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
      {
        /* Uses the same padding as the footer
           Uses an absolute height for the header so that it is possible to correctly align the top of the sticky tab in MainQuestions.tsx */ 
      }
      <header className="bg-slate-100 dark:bg-gray-800 sticky top-0 z-30 flex flex-row items-center w-full xl:px-4 lg:px-3 md:px-2 px-2 xl:h-18 lg:h-16 md:h-14 h-14">
        <div className="w-full flex flex-row items-center justify-between space-x-2">
          <Link to="/" className="xl:text-2xl text-xl font-semibold whitespace-nowrap dark:text-white">
            { "🧭 Godwin" }
          </Link>
          <div className="w-full flex flex-row items-center justify-end md:space-x-4">
            <button id="theme-toggle" type="button" className="fill-indigo-600 hover:fill-indigo-900 dark:fill-yellow-400 dark:hover:fill-yellow-200 rounded-lg text-sm p-2.5">
              <svg id="theme-toggle-dark-icon" className="hidden w-5 h-5" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path></svg>
              <svg id="theme-toggle-light-icon" className="hidden w-5 h-5" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" fillRule="evenodd" clipRule="evenodd"></path></svg>
            </button>
            { isAuthenticated ? 
              <div className="block text-black dark:text-white pr-2">
                <Balance amount={ balance !== null ? balance : undefined } />
              </div> : <></>
            }
            { isAuthenticated && authClient !== undefined ? 
              <button type="button" className="relative inline-flex items-center p-2 w-10 h-10 justify-center text-sm text-gray-500 rounded-lg md:hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600"
                onClick={(e)=>{setShowMenu(!showMenu); e.stopPropagation(); }}>
                <span className="sr-only">Open main menu</span>
                <svg className="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 17 14">
                  <path stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M1 1h15M1 7h15M1 13h15"/>
                </svg>
              </button> : 
              <button type="button" onClick={login} className="button-blue">
                Log in
              </button>
            }
            { isAuthenticated ? 
              <div className={`relative md:block md:w-auto ${showMenu ? "" : "hidden"}`} dir="rtl">
                <ul ref={popover} className="w-4/5-screen p-4 md:p-0 mt-4 md:mt-0 grow md:w-auto absolute md:relative inset-inline-start bg-slate-100 dark:bg-gray-800 font-medium flex flex-col border border-gray-300 rounded-lg md:flex-row-reverse md:items-center md:space-x-4 md:border-0 dark:border-gray-600">
                  <li>
                    { isAuthenticated && authClient !== undefined ?
                      <Link className="block py-2 px-3 text-end text-gray-700 dark:text-gray-300 hover:text-black dark:hover:text-white"
                        to={"/user/" + authClient.getIdentity().getPrincipal().toString()} onClick={(e) => { setShowMenu(!showMenu); }}>
                        { loggedUserName !== undefined ? loggedUserName : CONSTANTS.USER_NAME.DEFAULT }
                      </Link> : <></>
                    }
                  </li>
                  <li>
                    <div className="block py-2 px-3 rounded text-end md:text-start hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white w-full md:button-blue md:dark:text-white md:hover:text-white md:dark:hover:text-white hover:cursor-pointer"
                      onClick={(e) => { setShowMenu(!showMenu); setShowAskQuestion(true) } }>
                      Propose a vote
                    </div>
                  </li>
                  <li>
                    <Link className="block py-2 px-3 rounded text-end md:text-start hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white w-full md:button-blue md:dark:text-white md:hover:text-white md:dark:hover:text-white"
                      to={"/newsub"} onClick={(e) => { setShowMenu(!showMenu); } }>
                      Create new sub
                    </Link>
                  </li>
                </ul>
              </div> : <></>
            }
          </div>
        </div>
      </header>
    </>
  );
}

export default Header;