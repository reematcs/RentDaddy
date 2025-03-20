import { UserProfile } from '@clerk/react-router'
import React from 'react'
import PageTitleComponent from '../components/reusableComponents/PageTitleComponent'

const SettingsPage = () => {
    return (
        <div className='container d-flex justify-content-center align-items-center flex-column'>
            <PageTitleComponent title='Settings' />
            <UserProfile />
        </div>
    )
}

export default SettingsPage