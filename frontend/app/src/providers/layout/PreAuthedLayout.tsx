import React from 'react';
import { Breadcrumb, Divider, Layout, Menu, theme } from 'antd';
import { Link, Outlet } from 'react-router';

const { Header, Content, Footer } = Layout;

// TODO: Make sure to use the real user object from the auth provider
// Make sure to use the real user object from the auth provider
// const user = {
//     role: 'admin'
// };

const user = null;

const items = [
    // Todo: Make the home link go to the landing page if the user is not logged in and the appropriate dashboard if the user is logged in
    {
        key: '1',
        label: user ? <Link to={user.role === 'admin' ? '/admin' : '/tenant'}>Your Home</Link> : <Link to="/">Home</Link>,
    },
    {
        key: '2',
        label: user ? <Link to="/auth/logout">Logout</Link> : <Link to="/auth/login">Login</Link>,
    }
];

const PreAuthedLayout: React.FC = () => {
    const {
        token: { colorBgContainer, borderRadiusLG },
    } = theme.useToken();

    return (
        <Layout>
            <Header
                style={{
                    position: 'sticky',
                    top: 0,
                    zIndex: 1,
                    width: '100%',
                    display: 'flex',
                    alignItems: 'center',
                }}
            >
                <Link to="/">
                    <div className="demo-logo">
                        {/* Use a placeholder image */}
                        <img src="/logo.png" alt="logo" style={{ width: '64px', height: '64px' }} className='bg-white' />
                    </div>
                </Link>
                <Link to="/" style={{ flex: 1, textAlign: 'center', color: 'white', fontSize: '24px', textDecoration: 'none' }}>
                    RentDaddy
                </Link>
                <Menu
                    theme="dark"
                    mode="horizontal"
                    defaultSelectedKeys={['1']}
                    items={items}
                />
            </Header>
            <Content style={{ padding: '0 48px' }}>

                {/* TODO: Decide if we are using this */}
                {/* <Breadcrumb style={{ margin: '16px 0' }}>
                        <Breadcrumb.Item><Link to="/">Home</Link></Breadcrumb.Item>
                        <Breadcrumb.Item>Test</Breadcrumb.Item>
                        <Breadcrumb.Item>Breadcrumb</Breadcrumb.Item>
                    </Breadcrumb> 
                */}

                <div
                    style={{
                        padding: 24,
                        minHeight: 380,
                        background: colorBgContainer,
                        borderRadius: borderRadiusLG,
                    }}
                >
                    <Outlet />
                </div>
            </Content>

            {/* Footer Container */}
            <Footer style={{ textAlign: 'center', padding: '24px 50px', backgroundColor: '#f5f5f5' }}>
                {/* Rent Daddy */}
                <h3 className="footer-title" style={{ marginBottom: '16px', color: '#1a1a1a' }}>
                    Rent Daddy
                </h3>
                {/* Logo */}
                <img
                    // src="https://placehold.co/64x64?text=Logo"
                    src="/logo.png"
                    alt="logo"
                    className='footer-logo'
                    style={{
                        display: 'block',
                        margin: '0 auto',
                        marginBottom: '24px',
                        borderRadius: '8px'
                    }}
                />
                <div className="footer-links" style={{ marginBottom: '24px' }}>
                    <Link to="/about" style={{ padding: '0 16px', color: '#595959', textDecoration: 'none' }}>About</Link>
                    <Link to="/contact" style={{ padding: '0 16px', color: '#595959', textDecoration: 'none' }}>Contact</Link>
                    <Link to="/privacy" style={{ padding: '0 16px', color: '#595959', textDecoration: 'none' }}>Privacy Policy</Link>
                    <Link to="/terms" style={{ padding: '0 16px', color: '#595959', textDecoration: 'none' }}>Terms of Service</Link>
                </div>
                <p className='footer-text' style={{ margin: 0, color: '#8c8c8c', fontSize: '14px' }}>
                    Rent Daddy © {new Date().getFullYear()} | All Rights Reserved
                </p>
            </Footer>
        </Layout >
    );
};

export default PreAuthedLayout;