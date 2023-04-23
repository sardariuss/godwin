
function Footer() {
  return (
		<>
      <footer className="p-4 fixed bottom-0 w-full bg-white shadow md:flex md:items-center md:justify-between md:p-6 dark:bg-gray-800">
        <a href="https://internetcomputer.org/">
          <div className="flex flex-row">
            <div className="pl-5 sm:text-center text-l font-semibold text-gray-500 dark:text-gray-400">
              Powered by
            </div>
            <div className="w-2"/>
            <img src="ic.svg" className="flex h-5" alt="the internet computer"/>
          </div>
        </a>
      </footer>
    </>
  );
}

export default Footer;