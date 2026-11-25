import { PublishCommand, SNSClient } from '@aws-sdk/client-sns'
import type { FastifyBaseLogger } from 'fastify'
import { config } from '../config.js'

let sns: SNSClient | undefined

/**
 * Sends a transactional SMS.
 *  - SMS_PROVIDER=log  → only logs (local dev, no AWS needed)
 *  - SMS_PROVIDER=sns  → Amazon SNS. For India, register the sender ID + DLT template in AWS End User Messaging first.
 */
export async function sendSms(log: FastifyBaseLogger, phone: string, message: string) {
  if (config.SMS_PROVIDER === 'log') {
    log.info({ phone: phone.slice(0, -4).replace(/\d/g, '•') + phone.slice(-4) }, `[sms:log] ${message}`)
    return
  }
  sns ??= new SNSClient({ region: config.AWS_REGION })
  await sns.send(
    new PublishCommand({
      PhoneNumber: phone,
      Message: message,
      MessageAttributes: {
        'AWS.SNS.SMS.SMSType': { DataType: 'String', StringValue: 'Transactional' },
        'AWS.SNS.SMS.SenderID': { DataType: 'String', StringValue: config.SMS_SENDER_ID },
      },
    }),
  )
}
