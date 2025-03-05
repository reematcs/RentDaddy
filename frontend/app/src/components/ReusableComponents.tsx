import { Avatar, Button, Card, Col, Divider, Input, Row } from 'antd'
import AntDesignTableComponent from './AntDesignTableComponent'
import { SettingOutlined, UserOutlined } from '@ant-design/icons';
import TextArea from 'antd/es/input/TextArea';
import { useState } from 'react';
import UniversalSidebar from './UniversalSidebar';
import { Link } from 'react-router';
import RegistrationFormExample from './FormExample';
import TimeRelatedFormExample from './TimeRelatedFormExamples';

const ReusableComponents = () => {
    const [value, setValue] = useState('');

    return (
        <div className='reusable-components'>
            <div className='title text-center fs-1'>ReusableComponents</div>
            <h4 className='text-center mt-3 fst-italic fw-bold'>
                ***There is not much styling on this yet, kinda stock, <br /> just so we can get the components up and running.***
            </h4>

            {/* Back to Home Button */}
            <Link to="/" className='d-flex justify-content-center'>
                <Button type='primary' className='mt-3'>
                    Back to Home
                </Button>
            </Link>

            <Divider />

            {/* User Avatar */}
            <div className='user-avatar m-5 flex flex-column align-items-center'>
                <h2 className='fs-2'>User Avatar</h2>
                <Avatar size={64} icon={<UserOutlined />} />
            </div>

            <Divider />

            {/* Sider (Sidebar) */}
            <div className='sider m-5'>
                <h2 className='fs-2 text-center'>Layout: Sider (Sidebar) & Footer</h2>
                <p className='text-center'>The sidebar falls under the Layout Component of Ant Design.</p>
                <h1 className='text-center'>
                    MAKE SURE WE TALK ABOUT THIS IN THE NEXT MEETING OR IF SOMEONE KNOWS WHAT THE BEST WAY OF SETTING UP THE LAYOUT / SIDEBAR FEEL FREE TO CHANGE IT
                </h1>
                <UniversalSidebar />
            </div>

            <Divider />

            {/* Tables */}
            <div className='table m-5'>
                <h2>Table</h2>
                <AntDesignTableComponent />
            </div>

            <Divider />

            {/* Cards */}
            <div className='cards m-5'>
                <h2 className='fs-2 text-center'>Cards</h2>
                <Row gutter={16}>
                    <Col span={8}>
                        <Card title="Card title" variant="borderless">
                            Card content
                        </Card>
                    </Col>
                    <Col span={8}>
                        <Card title="Card title" variant="borderless">
                            Card content
                        </Card>
                    </Col>
                    <Col span={8}>
                        <Card title="Card title" variant="borderless">
                            Card content
                        </Card>
                    </Col>
                </Row>
            </div>

            <Divider />

            {/* Buttons */}
            <div className='buttons-examples m-5'>
                <h2 className='fs-2 text-center'>Buttons</h2>
                <div className='buttons-container flex flex-column align-items-center gap-2'>
                    {/* Primary Button */}
                    <div className='my-2'>
                        <h2>Primary Button</h2>
                        <Button type='primary' className='flex mx-auto'>Click me</Button>
                    </div>

                    {/* Confirm Button */}
                    <div className='my-2'>
                        <h2>Confirm Button</h2>
                        <Button className='bg-success flex mx-auto'> Click me</Button>
                    </div>

                    {/* Decline Button */}
                    <div className='my-2'>
                        <h2>Decline Button</h2>
                        <Button className='bg-danger flex mx-auto'>Click me</Button>
                    </div>

                    {/* Loading Button */}
                    <div className='my-2'>
                        <h2>Loading Button</h2>
                        <Button className='bg-primary flex mx-auto' loading>Click me</Button>
                    </div>

                    {/* Disabled Button */}
                    <div className='my-2'>
                        <h2>Disabled Button</h2>
                        <Button className='bg-secondary flex mx-auto' disabled>Click me</Button>
                    </div>

                    {/* Any other buttons? */}
                </div>
            </div>

            <Divider />

            {/* Text Area Examples*/}
            <div className='text-area-examples m-5'>

                <h2 className='fs-2 text-center'>Text Area Examples</h2>

                {/* Basic Input */}
                <div className='my-2'>
                    <h2>Basic Input</h2>
                    <Input className='my-2' placeholder="Basic usage" />
                </div>

                {/* Search Input */}
                <div className='my-2'>
                    <h2>Search Input</h2>
                    <Input className='my-2' addonAfter={<SettingOutlined />} defaultValue="mysite" />
                    <Input className='my-2' addonBefore="http://" suffix=".com" defaultValue="mysite" />
                </div>

                {/* Controlled Expanding Text Area */}
                <div className='my-2'>
                    <h2>Controlled Expanding Text Area</h2>
                    <TextArea
                        className='my-2'
                        value={value}
                        onChange={(e) => setValue(e.target.value)}
                        placeholder="Controlled autosize"
                        autoSize={{ minRows: 3, maxRows: 5 }}
                    />
                </div>

                <Divider />

                <div className='form-examples m-5 p-4 border rounded shadow-sm bg-light'>
                    <h2 className='fs-2 text-center mb-4 text-primary'>Form Examples</h2>
                    <div className='bg-white p-3 rounded'>
                        <h2 className='fs-3 text-center mb-4 text-primary'>
                            Registration Form
                        </h2>
                        <RegistrationFormExample />
                    </div>
                    <Divider />
                    <div className='bg-white p-3 rounded'>
                        <h2 className='fs-3 text-center mb-4 text-primary'>
                            Time Related Form Examples
                        </h2>
                        <TimeRelatedFormExample />
                    </div>
                </div>


                {/* Any other text area examples? */}
            </div>

            <Divider />

        </div >
    )
}

export default ReusableComponents