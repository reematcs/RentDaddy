package config

import (
	"fmt"
	"log"
	"net/smtp"
	"os"
)

type SMTPConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	TLSMode  string
}

func LoadSMTPConfig() (*SMTPConfig, error) {
	host := os.Getenv("SMTP_ENDPOINT_ADDRESS")
	port := os.Getenv("SMTP_PORT")
	user := os.Getenv("SMTP_USER")
	password := os.Getenv("SMTP_PASSWORD")
	tlsMode := os.Getenv("SMTP_TLS_MODE")
	from := os.Getenv("SMTP_FROM")

	if host == "" || port == "" || user == "" || password == "" || tlsMode == "" || from == "" {
		return nil, fmt.Errorf("one or more SMTP configuration variables (SMTP_ENDPOINT_ADDRESS, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_TLS_MODE, SMTP_FROM) must be set")
	}

	if tlsMode != "starttls" && tlsMode != "tls" {
		return nil, fmt.Errorf("Invalid SMTP_TLS_MODE: must be 'starttls' or 'tls'")
	}

	return &SMTPConfig{
		Host:     host,
		Port:     port,
		User:     user,
		Password: password,
		TLSMode:  tlsMode,
	}, nil
}

func SendEmail(to string, subject string, body string) error {
	smtpConfig, err := LoadSMTPConfig()
	if err != nil {
		return fmt.Errorf("failed to load SMTP config: %v", err)
	}

	from := os.Getenv("SMTP_FROM")

	msg := []byte("From: " + from + "\r\n" +
		"To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"\r\n" +
		body + "\r\n")

	addr := fmt.Sprintf("%s:%s", smtpConfig.Host, smtpConfig.Port)
	auth := smtp.PlainAuth("", smtpConfig.User, smtpConfig.Password, smtpConfig.Host)

	send_mail_err := smtp.SendMail(addr, auth, from, []string{to}, msg)

	if send_mail_err != nil {
		log.Printf("Failed to send email to %s: %v", to, err)
		return err
	}
	return nil
}
