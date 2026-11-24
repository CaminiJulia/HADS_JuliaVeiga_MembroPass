import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport } from 'nodemailer';

interface Mensagem {
  para: string;
  assunto: string;
  // Texto simples: clientes de e-mail sem HTML e o log de desenvolvimento.
  texto: string;
  html: string;
}

// Entrega uma mensagem; lança se não conseguir.
type Entrega = (m: Mensagem) => Promise<void>;

// Envio de e-mails, por um destes caminhos (o primeiro configurado vale):
// 1. EMAIL_APPS_SCRIPT_URL: um Google Apps Script na conta do Gmail envia
//    a mensagem (HTTPS). É o caminho da produção, porque hospedagens
//    gratuitas como o Render bloqueiam as portas de SMTP.
// 2. SMTP_HOST: SMTP direto (ex.: Gmail com senha de app), bom no computador.
// 3. Nenhum: nada é enviado; a mensagem aparece no log, para testar.
@Injectable()
export class EmailService {
  private readonly log = new Logger('Email');
  private readonly entrega: Entrega | null;

  constructor(config: ConfigService) {
    const appsScript = config.get<string>('EMAIL_APPS_SCRIPT_URL');
    const host = config.get<string>('SMTP_HOST');
    if (appsScript) {
      this.entrega = porAppsScript(
        appsScript,
        config.getOrThrow<string>('EMAIL_APPS_SCRIPT_SEGREDO'),
      );
    } else if (host) {
      this.entrega = porSmtp(config, host);
    } else {
      this.entrega = null;
      this.log.warn(
        'E-mail não configurado: as mensagens só aparecem neste log.',
      );
    }
  }

  // Devolve se o e-mail saiu. Nunca lança: quem chama decide o que fazer
  // (o cadastro, por exemplo, continua valendo mesmo sem o e-mail).
  async enviar(m: Mensagem): Promise<boolean> {
    if (!this.entrega) {
      this.log.log(`\nPara: ${m.para}\nAssunto: ${m.assunto}\n\n${m.texto}\n`);
      return false;
    }
    try {
      await this.entrega(m);
      return true;
    } catch (erro) {
      this.log.error(
        `Falha ao enviar "${m.assunto}" para ${m.para}: ${(erro as Error).message}`,
      );
      return false;
    }
  }

  enviarCodigoRecuperacao(para: string, nome: string, codigo: string) {
    const primeiroNome = nome.split(' ')[0];
    return this.enviar({
      para,
      assunto: `${codigo} é o seu código do MembroPass`,
      texto:
        `Olá, ${primeiroNome}!\n\nSeu código para criar uma nova senha no MembroPass é: ${codigo}\n\n` +
        'Ele vale por 15 minutos. Se você não pediu, ignore este e-mail: sua senha continua a mesma.',
      html: modelo(
        `Olá, ${escapar(primeiroNome)}!`,
        `<p>Use este código no app para criar uma nova senha:</p>
         <p style="font-size:32px;font-weight:800;letter-spacing:8px;margin:24px 0;color:#2B2FB8">${codigo}</p>
         <p>Ele vale por <b>15 minutos</b>. Se você não pediu, ignore este e-mail: sua senha continua a mesma.</p>`,
      ),
    });
  }

  enviarSenhaProvisoria(d: {
    para: string;
    nome: string;
    organizacao: string;
    senha: string;
    papel: 'membro' | 'operador';
  }) {
    const primeiroNome = d.nome.split(' ')[0];
    const oQue =
      d.papel === 'membro'
        ? 'sua carteirinha digital'
        : 'o acesso de operador, para validar o check-in das carteirinhas';
    return this.enviar({
      para: d.para,
      assunto: `Seu acesso ao MembroPass - ${d.organizacao}`,
      texto:
        `Olá, ${primeiroNome}!\n\n${d.organizacao} liberou ${oQue} no MembroPass.\n\n` +
        `E-mail: ${d.para}\nSenha provisória: ${d.senha}\n\n` +
        'No primeiro acesso, o app vai pedir que você crie uma senha só sua.',
      html: modelo(
        `Olá, ${escapar(primeiroNome)}!`,
        `<p><b>${escapar(d.organizacao)}</b> liberou ${oQue} no MembroPass.</p>
         <table style="margin:20px 0;border-collapse:collapse">
           <tr><td style="padding:4px 12px 4px 0;color:#666">E-mail</td><td><b>${escapar(d.para)}</b></td></tr>
           <tr><td style="padding:4px 12px 4px 0;color:#666">Senha provisória</td>
               <td style="font-size:20px;font-weight:800;letter-spacing:2px;color:#2B2FB8">${escapar(d.senha)}</td></tr>
         </table>
         <p>No primeiro acesso, o app vai pedir que você crie uma senha só sua.</p>`,
      ),
    });
  }
}

function escapar(texto: string) {
  return texto.replace(
    /[&<>"']/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[
        c
      ]!,
  );
}

// Moldura simples, com a cor da marca, que funciona nos clientes de e-mail.
function modelo(titulo: string, corpo: string) {
  return `<!doctype html><html><body style="margin:0;background:#f3f3fa;font-family:Arial,sans-serif;color:#1c1f3a">
  <div style="max-width:480px;margin:0 auto;padding:24px">
    <div style="background:#2B2FB8;color:#fff;border-radius:16px 16px 0 0;padding:20px 24px;font-size:20px;font-weight:800">MembroPass</div>
    <div style="background:#fff;border-radius:0 0 16px 16px;padding:24px;line-height:1.5">
      <h2 style="margin-top:0">${titulo}</h2>${corpo}
    </div>
    <p style="font-size:12px;color:#888;text-align:center">Mensagem automática. Não responda este e-mail.</p>
  </div></body></html>`;
}

function porSmtp(config: ConfigService, host: string): Entrega {
  const usuario = config.get<string>('SMTP_USUARIO');
  const remetente =
    config.get<string>('EMAIL_REMETENTE') ??
    `MembroPass <${usuario ?? 'nao-responda@membropass.dev'}>`;
  const porta = Number(config.get('SMTP_PORTA', 465));
  const transporte = createTransport({
    host,
    port: porta,
    secure: porta === 465, // 465: TLS direto; 587: STARTTLS
    auth: { user: usuario, pass: config.get<string>('SMTP_SENHA') },
  });
  return async (m) => {
    await transporte.sendMail({
      from: remetente,
      to: m.para,
      subject: m.assunto,
      text: m.texto,
      html: m.html,
    });
  };
}

// O script (api/scripts/envio-email.gs) confere o segredo e envia pelo
// Gmail da conta onde foi publicado. Responde {"ok": true} ou {"erro": ...}.
function porAppsScript(url: string, segredo: string): Entrega {
  return async (m) => {
    const resposta = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ segredo, ...m }),
      signal: AbortSignal.timeout(20_000),
    });
    const corpo = await resposta.text();
    let ok = false;
    try {
      ok = (JSON.parse(corpo) as { ok?: boolean }).ok === true;
    } catch {
      // HTML de erro do Google (ex.: script não publicado para "Qualquer pessoa").
    }
    if (!ok) {
      throw new Error(
        `Apps Script respondeu ${resposta.status}: ${corpo.slice(0, 200)}`,
      );
    }
  };
}
