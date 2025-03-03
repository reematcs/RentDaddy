import { Navigate, Outlet } from 'react-router';

const ProtectedRoutes = () => {
    const user = true;

    return user ? <Outlet /> : <Navigate to="/authentication/login" />;
}

export default ProtectedRoutes