import React, { useState } from 'react';
import { Phone, Users, ClipboardList, CheckCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';

export default function SadotMDT() {
  const [postal, setPostal] = useState('');
  const [reason, setReason] = useState('');

  return (
    <div className="h-full w-full bg-[#39334d] text-white p-4 flex flex-col">
      <header className="flex items-center justify-between mb-2">
        <h1 className="text-xl font-bold">SADOT MDT</h1>
        <Tabs defaultValue="dashboard" className="space-x-2">
          <TabsList>
            <TabsTrigger value="dashboard"><Users className="inline-block mr-1" size={16}/>Units</TabsTrigger>
            <TabsTrigger value="calls"><Phone className="inline-block mr-1" size={16}/>New</TabsTrigger>
            <TabsTrigger value="active"><ClipboardList className="inline-block mr-1" size={16}/>Active</TabsTrigger>
            <TabsTrigger value="history"><CheckCircle className="inline-block mr-1" size={16}/>History</TabsTrigger>
          </TabsList>
        </Tabs>
      </header>

      <div className="flex-1 overflow-auto">
        <TabsContent value="dashboard">
          <Card className="bg-[#2f2c3f]">
            <CardHeader>
              <CardTitle>On-Duty Units</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Dynamically list units here */}
              <p>No units online</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="calls">
          <Card className="bg-[#2f2c3f]">
            <CardHeader>
              <CardTitle>New 311 Call</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <input
                type="text"
                placeholder="Postal"
                value={postal}
                onChange={e => setPostal(e.target.value)}
                className="w-full p-2 rounded bg-[#4a4760] text-white"
              />
              <textarea
                placeholder="Reason"
                value={reason}
                onChange={e => setReason(e.target.value)}
                className="w-full p-2 rounded bg-[#4a4760] text-white h-24"
              />
              <Button className="w-full bg-[#ff8900] hover:bg-[#e27a00]">
                Send Call
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="active">
          <Card className="bg-[#2f2c3f]">
            <CardHeader>
              <CardTitle>Active Calls</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Loop through active calls, each with Complete button */}
              <p>No active calls</p>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="history">
          <Card className="bg-[#2f2c3f]">
            <CardHeader>
              <CardTitle>Call History</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Loop through last 15 completed calls */}
              <p>No history</p>
            </CardContent>
          </Card>
        </TabsContent>
      </div>
    </div>
  );
}
