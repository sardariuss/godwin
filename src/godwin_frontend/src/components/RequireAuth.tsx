import { Navigate, Outlet } from "react-router-dom";

type RequireAuthArgs = {
  isAuthenticated: boolean;
}

const RequireAuth = ({ isAuthenticated } : RequireAuthArgs) => {

  if (!isAuthenticated) {
    // Redirect them to the login page
    return <Navigate to="/login"/>;
  }

  return <Outlet/>;
}

export default RequireAuth;