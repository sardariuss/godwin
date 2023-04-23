import { Link } from "react-router-dom";

import { ActorContext } from "../ActorContext"

import { useContext } from "react";

type Props = {
  login: () => (void),
  setShowAskQuestion: (boolean) => (void)
};

function Header({login, setShowAskQuestion}: Props) {

  const {isAuthenticated, authClient} = useContext(ActorContext);

  return (
		<>
      <nav className="bg-white fixed w-full border-gray-200 px-2 sm:px-4 py-2.5 dark:bg-gray-800">
        <div className="container flex flex-row justify-between items-center mx-auto">
          <Link to="/">
            <div className="flex flex-row items-center">
              <img src="battery.svg" className="w-10 h-10" alt="Logo"/>
              <div className="w-2"></div>
              <div className="self-center text-xl font-semibold whitespace-nowrap dark:text-white">Godwin</div>
            </div>
          </Link>
          <div className="hidden w-full md:block md:w-auto" id="mobile-menu">
            <ul className="flex flex-col items-center mt-4 md:flex-row md:space-x-8 md:mt-0 md:text-sm md:font-medium">
              { isAuthenticated ? 
              <li>
                <button type="button" onClick={(e) => setShowAskQuestion(true)} className="text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 text-center">
                  Suggest a question
                </button>
              </li> : <></>
              }
              <li>
                { isAuthenticated && authClient !== undefined ? 
                  <Link to={"/profile/" + authClient.getIdentity().getPrincipal().toString()} className="block text-gray-700 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">
                    My profile
                  </Link> :
                  <button type="button" onClick={login} className="text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 text-center">
                    Log in
                  </button>
                }
              </li>
            </ul>
          </div>
        </div>
      </nav>
    </>
  );
}

export default Header;