import React from 'react';
import {
    AppstoreOutlined,
    BarChartOutlined,
    CloudOutlined,
    HomeOutlined,
    SettingOutlined,
    ShopOutlined,
    TeamOutlined,
    UploadOutlined,
    UserOutlined,
    VideoCameraOutlined,
} from '@ant-design/icons';
import type { MenuProps } from 'antd';
import { Avatar, Divider, Layout, Menu, theme } from 'antd';
import { Link, Outlet, useLocation } from 'react-router';

const { Header, Content, Footer, Sider } = Layout;

const siderStyle: React.CSSProperties = {
    overflow: 'auto',
    height: '95vh',
    position: 'sticky',
    insetInlineStart: 0,
    top: 0,
    bottom: 0,
    scrollbarWidth: 'thin',
    scrollbarGutter: 'stable',
};

// TODO: Set Admin or Tenant to open on default based on user role
const items: MenuProps['items'] = [
    {
        key: 'home',
        icon: React.createElement(HomeOutlined),
        label: <Link to="/">Home</Link>
    },
    {
        key: 'admin',
        icon: React.createElement(TeamOutlined),
        label: <Link to="/admin">Admin</Link>,
        children: [
            // Admin Dashboard
            {
                key: 'admin-dashboard',
                label: <Link to="/admin">Admin Dashboard</Link>
            },
            // Apartment Setup and Details Management Page
            {
                key: 'apartment',
                label: <Link to="/admin/init-apartment-complex">Apartment Setup</Link>
            },
            // Add a tenant
            {
                key: 'tenant',
                label: <Link to="/admin/add-tenant">Add Tenant</Link>
            },
            // View Digital Leases
            {
                key: 'admin-view-and-edit-leases',
                label: <Link to="/admin/admin-view-and-edit-leases">View Digital Leases</Link>
            },
            // Work Order / Complaint Management Page
            {
                key: 'admin-view-and-edit-work-orders-and-complaints',
                label: <Link to="/admin/admin-view-and-edit-work-orders-and-complaints">Work Orders & Complaints</Link>
            }
        ]
    },
    {
        key: 'tenant',
        icon: React.createElement(UserOutlined),
        label: <Link to="/tenant">Tenant</Link>,
        children: [
            // Tenant Dashboard
            {
                key: 'tenant-dashboard',
                label: <Link to="/tenant">Tenant Dashboard</Link>
            },
            // Guest Parking
            {
                key: 'guest-parking',
                label: <Link to="/tenant/guest-parking">Guest Parking</Link>
            },
            // View Digital Leases
            {
                key: 'tenant-view-and-edit-leases',
                label: <Link to="/tenant/tenant-view-and-edit-leases">View Digital Leases</Link>
            },
            // Work Order / Complaint Management Page
            {
                key: 'tenant-work-orders-and-complaints',
                label: <Link to="/tenant/tenant-work-orders-and-complaints">Work Orders & Complaints</Link>
            }

        ]
    },
    {
        key: 'settings',
        icon: React.createElement(SettingOutlined),
        label: <Link to="/components/settings">Settings</Link>
    }
];

const AuthenticatedLayout: React.FC = () => {
    const {
        token: { colorBgContainer, borderRadiusLG },
    } = theme.useToken();

    // Get the path from the current url and check if it contains admin or tenant and set the default selected key based on that
    const path = useLocation().pathname;
    const isAdmin = path.includes('/admin');
    const isTenant = path.includes('/tenant');

    const defaultSelectedKey = isAdmin ? 'admin' : isTenant ? 'tenant' : 'dashboard';


    console.log(isAdmin, isTenant, "isAdmin, isTenant");

    return (
        <Layout hasSider>
            {/* Sidebar Container */}
            <Sider style={siderStyle}>

                {/* Logo and Title Container */}
                <div className="logo-container d-flex flex-column align-items-center justify-content-center py-4">
                    <Divider className="divider-text border-white" />
                    <Link to="/" className="text-decoration-none">
                        <h1 className="logo-title text-white mb-3 text-center">Rent Daddy</h1>
                        <img
                            src="/logo.png"
                            alt="Rent Daddy Logo"
                            className="logo-image mx-auto d-block bg-white"
                            width={64}
                            height={64}
                        />
                    </Link>
                    <Divider className="divider-text border-white" />
                </div>

                {/* Menu Container */}
                <Menu theme="dark" mode="inline" defaultSelectedKeys={[defaultSelectedKey]} defaultOpenKeys={[defaultSelectedKey]} items={items} />

                {/* Avatar and Login Container */}
                <div className="avatar-container d-flex flex-column position-absolute bottom-0 w-100">
                    <Divider className="divider-text border-white" />
                    <Link to="/auth/login" className="text-decoration-none">
                        <div className="d-flex align-items-center justify-content-center gap-2 mb-4">
                            <p className="login-text text-white m-0">Login</p>
                            <Avatar className="avatar-icon" size={48} icon={<UserOutlined />} />
                        </div>
                    </Link>
                </div>

            </Sider>

            {/* Content Container */}
            <Layout>
                {/* <Header style={{ padding: 0, background: colorBgContainer }} /> */}
                <Content style={{ margin: '24px 16px 0', overflow: 'initial' }}>
                    <div
                        style={{
                            padding: 24,
                            textAlign: 'center',
                            background: colorBgContainer,
                            borderRadius: borderRadiusLG,
                        }}
                    >
                        <Outlet />
                    </div>
                </Content>
                {/* Footer Container */}
                <Footer style={{ textAlign: 'center' }}>
                    <Divider className='divider-text border-black' />
                    <p>
                        Rent Daddy © {new Date().getFullYear()} Created by Rent Daddy
                    </p>
                </Footer>
            </Layout>
        </Layout>
    );
};

export default AuthenticatedLayout;