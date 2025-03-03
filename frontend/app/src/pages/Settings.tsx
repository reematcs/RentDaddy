// THIS IS JUST A TEMPLATE FOR THE SETTINGS PAGE
// TODO: Make sure to move this to the AuthenticatedLayout and use specific settings for each user role
// TODO: Change the template to be more specific to the user role

import React from 'react'

const Settings = () => {
    return (
        <div className="settings-container">
            <h1 className="mb-4">Settings</h1>

            <div className="settings-section mb-4">
                <h2>Account Settings</h2>
                <div className="setting-item p-3 border rounded mb-3">
                    <h3>Profile Information</h3>
                    <p>Update your account details and personal information</p>
                </div>
                <div className="setting-item p-3 border rounded mb-3">
                    <h3>Password & Security</h3>
                    <p>Manage your password and security preferences</p>
                </div>
            </div>

            <div className="settings-section mb-4">
                <h2>Notifications</h2>
                <div className="setting-item p-3 border rounded mb-3">
                    <h3>Email Notifications</h3>
                    <p>Choose which emails you'd like to receive</p>
                </div>
                <div className="setting-item p-3 border rounded">
                    <h3>Push Notifications</h3>
                    <p>Manage your mobile and browser notifications</p>
                </div>
            </div>

            <div className="settings-section">
                <h2>Privacy</h2>
                <div className="setting-item p-3 border rounded">
                    <h3>Privacy Settings</h3>
                    <p>Control your privacy preferences and data sharing options</p>
                </div>
            </div>
        </div>
    )
}

export default Settings