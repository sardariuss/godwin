import { Polarization} from "./../../../declarations/godwin_backend/godwin_backend.did";

type Props = {
  polarization: Polarization,
};

const PolarizationComponent = ({polarization}: Props) => {

  const total = polarization.left + polarization.center + polarization.right; 

  function getPercentage(side_aggregate){
    return Math.round(side_aggregate / total * 100.0);
  };
  
	return (
    <>
      <div className="flex flex-row w-20">
        <div className={`h-2.5 bg-red-600 dark:bg-red-600`} style={{width: `${getPercentage(polarization.left)}%`}}></div>
        <div className={`h-2.5 bg-gray-600 dark:bg-gray-600`} style={{width: `${getPercentage(polarization.center)}%`}}></div>
        <div className={`h-2.5 bg-green-600 dark:bg-green-600`} style={{width: `${getPercentage(polarization.right)}%`}}></div>
      </div>
    </>
	);
};

export default PolarizationComponent;
