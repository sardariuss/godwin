import { Link } from "react-router-dom";

import ActorContext from "../ActorContext"

import { _SERVICE } from "./../../declarations/godwin_backend/godwin_backend.did";

import { useEffect, useState, useContext } from "react";
import { ActorSubclass } from "@dfinity/agent";

type ActorContextValues = {
  actor: ActorSubclass<_SERVICE>,
  logged_in: boolean
};

function Header({login}: any) {

  const {logged_in} = useContext(ActorContext) as ActorContextValues;

  return (
		<>
      <nav className="bg-white border-gray-200 px-2 sm:px-4 py-2.5 dark:bg-gray-800">
        <div className="container flex flex-row justify-between items-center mx-auto">
          <Link to="/">
            <div className="flex flex-row items-center">
              <img src="battery.svg" className="w-10 h-10" alt="Logo"/>
              <div className="w-2"></div>
              <label className="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Godwin</label>
            </div>
          </Link>
          <div className="hidden w-full md:block md:w-auto" id="mobile-menu">
            <ul className="flex flex-col mt-4 md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium">
              <li>
                <a href="#" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Interest</a>
              </li>
              <li>
                <a href="#/opinion" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Opinion</a>
              </li>
              <li>
                <a href="#/categorization" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Categorization</a>
              </li>
              <li>
                <a href="#/archives" className="block py-2 pr-4 pl-3 text-gray-700 border-b border-gray-100 hover:bg-gray-50 md:hover:bg-transparent md:border-0 md:hover:text-blue-700 md:p-0 dark:text-gray-400 md:dark:hover:text-white dark:hover:bg-gray-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700">Archives</a>
              </li>
              <li>
                <button type="button" onClick={login} className="text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 text-center mr-2 mb-2">
                  { logged_in ? "Log out" : "Log in" }
                </button>
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </>
  );
}

export default Header;