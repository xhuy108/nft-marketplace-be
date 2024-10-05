const nodemailer = require("nodemailer");
const config = require("../config");
const logger = require("../utils/logger");
const fs = require("fs").promises;
const path = require("path");
const handlebars = require("handlebars");

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      host: config.email.smtp.host,
      port: config.email.smtp.port,
      secure: config.email.secure,
      auth: config.smtp.auth,
    });
  }

  async sendEmail(to, subject, html, attachments = []) {
    try {
      const mailOptions = {
        from: config.email.from,
        to,
        subject,
        html,
        attachments,
      };

      const info = await this.transporter.sendMail(mailOptions);
      logger.info(`Email sent: ${info.messageId}`);
      return info;
    } catch (error) {
      logger.error("Error sending email:", error);
      throw new Error("Failed to send email");
    }
  }

  async loadTemplate(templateName) {
    const filePath = path.join(
      __dirname,
      "../templates",
      `${templateName}.hbs`
    );
    const template = await fs.readFile(filePath, "utf-8");
    return handlebars.compile(template);
  }

  async sendWelcomeEmail(to) {
    try {
      const template = await this.loadTemplate("welcome");
      const html = template({
        name: to.split("@")[0],
        loginUrl: `${config.email.clientUrl}/login`,
      });

      await this.sendEmail(to, "Welcome to NFT Marketplace!", html, [
        {
          filename: "welcome.jpg",
          path: path.join(__dirname, "../assets/welcome.jpg"),
          cid: "welcome-image",
        },
      ]);
    } catch (error) {
      logger.error("Error sending welcome email:", error);
      throw new Error("Failed to send welcome email");
    }
  }

  async sendPasswordResetEmail(to, resetLink) {
    try {
      const template = await this.loadTemplate("passwordReset");
      const html = template({
        name: to.split("@")[0],
        resetLink,
        expirationTime: "1 hour",
      });

      await this.sendEmail(to, "Reset Your NFT Marketplace Password", html);
    } catch (error) {
      logger.error("Error sending password reset email:", error);
      throw new Error("Failed to send password reset email");
    }
  }

  async sendNFTSaleConfirmation(to, nftDetails) {
    try {
      const template = await this.loadTemplate("nftSaleConfirmation");
      const html = template({
        name: to.split("@")[0],
        nftName: nftDetails.name,
        price: nftDetails.price,
        buyer: nftDetails.buyer,
        transactionId: nftDetails.transactionId,
        marketplaceUrl: `${config.clientUrl}/marketplace`,
      });

      await this.sendEmail(to, "Your NFT Has Been Sold!", html, [
        {
          filename: "nft-sold.jpg",
          path: path.join(__dirname, "../assets/nft-sold.jpg"),
          cid: "nft-sold-image",
        },
      ]);
    } catch (error) {
      logger.error("Error sending NFT sale confirmation email:", error);
      throw new Error("Failed to send NFT sale confirmation email");
    }
  }

  async sendNewBidNotification(to, bidDetails) {
    try {
      const template = await this.loadTemplate("newBidNotification");
      const html = template({
        name: to.split("@")[0],
        nftName: bidDetails.nftName,
        bidAmount: bidDetails.bidAmount,
        bidder: bidDetails.bidder,
        auctionEndTime: bidDetails.auctionEndTime,
        nftUrl: `${config.clientUrl}/nft/${bidDetails.nftId}`,
      });

      await this.sendEmail(to, "New Bid on Your NFT!", html);
    } catch (error) {
      logger.error("Error sending new bid notification email:", error);
      throw new Error("Failed to send new bid notification email");
    }
  }
}

module.exports = new EmailService();
