import type { ReactElement } from 'react'
import Home from './Home'
import Orders from './Orders'
import { Delivering, OrderDetails, PickupQR } from './OrderFlow'
import { Delivered, HandOver } from './Deliver'
import { Earnings, Transactions } from './Money'
import { AddPayout, BankDetails, BankOnboarding, BankPayout, EditBankAccount } from './Bank'
import { Language, PersonalInfo, Profile, Settings } from './Profile'
import { DocsOnboarding, MyDocuments, Vehicle } from './Docs'
import { GovId, Verification } from './Verify'
import { ChangeCity, Zone } from './Zone'
import { About, Help, Notifications, SOS, SupportChat } from './Support'

/** Figma frame id -> real component. Frames not listed fall back to the exported image. */
export const built: Record<string, ReactElement> = {
  '1:814': <Home />,
  '1:944': <Orders tab="active" />,
  '17:242': <Orders tab="upcoming" />,
  '1:1072': <Orders tab="completed" />,
  '1:1698': <Orders tab="active" offline />,
  '1:1223': <OrderDetails />,
  '1:4029': <PickupQR />,
  '1:1359': <Delivering />,
  '1:1488': <HandOver />,
  '1:1593': <Delivered />,
  '1:1816': <Earnings />,
  '1:1953': <Transactions />,
  '1:2083': <BankPayout />,
  '1:2195': <AddPayout />,
  '1:2711': <BankDetails />,
  '1:708': <BankOnboarding />,
  '17:1065': <EditBankAccount />,
  '1:2301': <Profile />,
  '1:2459': <PersonalInfo />,
  '1:2934': <Settings />,
  '1:3080': <Language />,
  '1:583': <DocsOnboarding />,
  '1:2564': <MyDocuments />,
  '1:2807': <Vehicle />,
  '1:3651': <GovId />,
  '1:3770': <Verification />,
  '1:3906': <Zone />,
  '17:39': <ChangeCity />,
  '1:3289': <Help />,
  '33:5': <SupportChat />,
  '1:3417': <Notifications />,
  '1:3533': <SOS />,
  '1:3185': <About />,
}
