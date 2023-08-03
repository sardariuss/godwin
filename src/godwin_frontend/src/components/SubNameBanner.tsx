import { Sub } from "../ActorContext";

import React   from "react";

type Props = {
  sub: Sub;
};

const SubBanner = ({sub} : Props) => {

  return (
    <div className="w-full text-center items-center bg-gradient-to-r from-purple-200 dark:from-purple-700 from-10% dark:via-indigo-800 via-indigo-100 via-30% dark:to-sky-600 to-sky-200 to-90% text-black dark:text-white font-medium pt-2 pb-1">
      { sub.info.name }
    </div>
  );
}

export default SubBanner;