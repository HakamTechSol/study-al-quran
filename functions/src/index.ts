import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {createTransport} from "nodemailer";

initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "us-central1",
});

// Gmail SMTP Configuration
const gmailEmail = "Memosad1986@gmail.com";
const gmailPassword = "ifia httn szre kmbb";

const transporter = createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

interface Teacher {
  email: string;
  name: string;
  phone?: string;
  region?: string;
  rate?: number;
  isActive?: boolean;
}

export const sendTeacherWelcomeEmail = onDocumentCreated(
  {
    document: "teachers/{teacherId}",
    region: "us-central1",
    maxInstances: 5,
  },
  async (event) => {
    try {
      logger.info("📧 Teacher welcome email function triggered", {
        teacherId: event.params.teacherId,
      });

      const snapshot = event.data;
      if (!snapshot) {
        logger.warn("No data associated with the event");
        return;
      }

      const teacherData = snapshot.data() as Teacher;
      const teacherId = event.params.teacherId;

      const {email, name, phone, region, rate} = teacherData;

      logger.info(`Processing teacher: ${name} (${email})`);

      const resetLink =
        await getAuth().generatePasswordResetLink(email);
      logger.info("Password reset link generated");

      const htmlContent = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" 
      content="width=device-width, initial-scale=1.0">
    <title>Welcome to StudyAlQuran</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, 
              Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f9f9f9;
        }
        .header {
            background: linear-gradient(
              135deg, 
              #4CAF50, 
              #2E7D32
            );
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px 10px 0 0;
        }
        .content {
            background: white;
            padding: 40px;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .button {
            display: inline-block;
            background: linear-gradient(
              to right, 
              #4CAF50, 
              #45a049
            );
            color: white;
            padding: 14px 32px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: bold;
            font-size: 16px;
            margin: 20px 0;
        }
        .info-box {
            background: #f0f9ff;
            border-left: 4px solid #2196F3;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📚 StudyAlQuran</h1>
        <h2>Your Teacher Account is Ready!</h2>
    </div>
    
    <div class="content">
        <p>
          Assalamualaikum <strong>${name}</strong>,
        </p>
        
        <p>
          Welcome to the StudyAlQuran teaching community! 
          Your account has been successfully created as a teacher.
        </p>
        
        <div class="info-box">
            <h3>📋 Your Account Information:</h3>
            <p><strong>👤 Name:</strong> ${name}</p>
            <p><strong>📧 Email:</strong> ${email}</p>
            <p>
              <strong>📱 Phone:</strong> 
              ${phone || "Not provided"}
            </p>
            <p>
              <strong>📍 Region:</strong> 
              ${region || "Not specified"}
            </p>
            <p>
              <strong>💰 Rate per class:</strong> 
              Rs ${rate || "0"}
            </p>
        </div>
        
        <p>
          To get started, please set your password by clicking 
          the button below:
        </p>
        
        <center>
            <a href="${resetLink}" class="button">
              🔐 Set Your Password
            </a>
        </center>
        
        <p><strong>📝 Next Steps:</strong></p>
        <ol>
            <li>Set your password using the link above</li>
            <li>Login to your account</li>
            <li>Complete your profile</li>
            <li>Setup your teaching schedule</li>
            <li>Start accepting students</li>
        </ol>
        
        <p>Need assistance? We're here to help!</p>
        <p>
          📧 Email: 
          <a href="mailto:support@studyalquran.com">
            support@studyalquran.com
          </a>
        </p>
        
        <hr>
        
        <p style="color: #666; font-size: 12px;">
            This is an automated message. 
            Please do not reply to this email.<br>
            © ${new Date().getFullYear()} StudyAlQuran. 
            All rights reserved.
        </p>
    </div>
</body>
</html>
      `;

      const textContent = `
Welcome to StudyAlQuran!

Assalamualaikum ${name},

Your teacher account has been created successfully.

ACCOUNT DETAILS:
Name: ${name}
Email: ${email}
Phone: ${phone || "Not provided"}
Region: ${region || "Not specified"}
Rate per class: Rs ${rate || "0"}

GET STARTED:
1. Set your password: ${resetLink}
2. Complete your profile
3. Setup teaching schedule
4. Start accepting students

Need help? Contact: support@studyalquran.com

© ${new Date().getFullYear()} StudyAlQuran
      `;

      // Send email
      const info = await transporter.sendMail({
        from: `"StudyAlQuran" <${gmailEmail}>`,
        to: email,
        subject: `🎉 Welcome to StudyAlQuran, ${name}!`,
        html: htmlContent,
        text: textContent,
      });

      logger.info(`✅ Email sent successfully: ${info.messageId}`, {
        teacherId,
        email,
      });

      const db = getFirestore();
      await db.collection("teachers").doc(teacherId).update({
        welcomeEmailSent: true,
        welcomeEmailSentAt: FieldValue.serverTimestamp(),
        lastEmailType: "welcome",
        emailMessageId: info.messageId,
      });

      logger.info(`✅ Teacher ${teacherId} updated in Firestore`);
    } catch (error: unknown) {
      const err = error as Error;
      logger.error("❌ Error in sendTeacherWelcomeEmail:", err);

      // Log error to Firestore
      try {
        const db = getFirestore();
        await db.collection("email_errors").add({
          teacherId: event.params.teacherId,
          error: err.message || err.toString(),
          timestamp: FieldValue.serverTimestamp(),
          stack: err.stack || "No stack trace",
        });
        logger.info("✅ Error logged to Firestore");
      } catch (logError) {
        logger.error("❌ Failed to log error:", logError);
      }
    }
  }
);

export const helloWorld = onRequest(
  {
    region: "us-central1",
    maxInstances: 5,
  },
  (request, response) => {
    logger.info("Hello logs!", {structuredData: true});
    response.json({
      message: "Hello from Firebase!",
      timestamp: new Date().toISOString(),
      status: "active",
    });
  }
);

export const sendWelcomeEmailManual = onRequest(
  {
    region: "us-central1",
    maxInstances: 5,
    cors: true,
  },
  async (request, response) => {
    try {
      const {teacherId} = request.body;

      if (!teacherId) {
        response.status(400).json({
          error: "Teacher ID is required",
        });
        return;
      }

      const db = getFirestore();
      const teacherDoc =
        await db.collection("teachers").doc(teacherId).get();

      if (!teacherDoc.exists) {
        response.status(404).json({
          error: "Teacher not found",
        });
        return;
      }

      const teacherData = teacherDoc.data() as Teacher;
      const resetLink =
        await getAuth()
          .generatePasswordResetLink(teacherData.email);

      await transporter.sendMail({
        from: `"StudyAlQuran" <${gmailEmail}>`,
        to: teacherData.email,
        subject: `Welcome ${teacherData.name}!`,
        html: `
          <h1>Welcome ${teacherData.name}</h1>
          <p>
            <a href="${resetLink}">
              Click here to set your password
            </a>
          </p>
        `,
      });

      response.json({
        success: true,
        message: "Email sent successfully",
        teacherId,
      });
    } catch (error: unknown) {
      const err = error as Error;
      logger.error("Manual email error:", err);
      response.status(500).json({
        error: err.message || "Failed to send email",
      });
    }
  }
);
